# Appendix H: Multi-Organization Design, Roles, and Scaling

The tutorial version of GreyMatter Feedback is designed for one organization with a single administrator password.

That is a good starting point for:

- A training provider.
- A small conference organizer.
- An internal company team.
- A school department.
- A single course operator.

However, many real deployments eventually need to support multiple organizations, multiple administrators, and different permission levels.

This appendix explains how GreyMatter Feedback can evolve from a single-organization application into a secure multi-organization platform.

---

## H.1 What multi-tenancy means

A **tenant** is one organization using a shared application.

For example:

```text
Tenant 1: Acme Training
Tenant 2: Northwind University
Tenant 3: Contoso Events
```

Each organization should see only its own:

- Events.
- Courses.
- Sessions.
- Forms.
- Participant responses.
- Analytics.
- CSV exports.
- PDF reports.
- Administrators.

The core isolation rule is:

> An administrator from one organization must never be able to view or modify data belonging to another organization.

---

## H.2 Current single-organization model

The tutorial currently uses this simplified structure:

```text
Event
  └── Session
        ├── FormVersion
        ├── Response
        └── Report
```

Administrator access is based on one shared secret:

```dotenv
ADMIN_PASSWORD="..."
```

This is intentionally simple, but it has limitations:

```text
All administrators share one password.
No individual identity exists.
No role permissions exist.
No audit trail identifies who changed a form.
No organization boundary exists.
```

---

## H.3 Recommended multi-tenant hierarchy

A multi-organization version should introduce an `Organization` model.

```text
Organization
  ├── Members
  ├── Events
  │     └── Sessions
  │           ├── FormVersions
  │           ├── Responses
  │           └── Reports
  └── Settings
```

The full hierarchy becomes:

```text
Organization
  └── Event or Course
        └── Session
              ├── FormVersion
              │     └── Question
              │
              ├── Response
              │     └── Answer
              │
              └── Report
```

Example:

```text
Organization: Acme Training
└── Event: TypeScript Foundations
    └── Session: Module 1 — Type Basics
        └── Form Version 1

Organization: Northwind University
└── Event: Computer Science Orientation
    └── Session: Welcome Session
        └── Form Version 1
```

---

## H.4 Recommended organization and user schema

A future Prisma schema can add these models.

### `prisma/schema.prisma`

```prisma
model Organization {
  id        String        @id @default(uuid()) @db.Uuid
  name      String        @db.VarChar(255)
  slug      String        @unique @db.VarChar(100)
  createdAt DateTime      @default(now()) @map("created_at")

  members   OrganizationMember[]
  events    Event[]

  @@map("organizations")
}

model AdminUser {
  id           String               @id @default(uuid()) @db.Uuid
  email        String               @unique @db.VarChar(320)
  passwordHash String               @map("password_hash") @db.Text
  displayName  String?              @map("display_name") @db.VarChar(255)
  isActive     Boolean              @default(true) @map("is_active")
  createdAt    DateTime             @default(now()) @map("created_at")
  updatedAt    DateTime             @updatedAt @map("updated_at")

  memberships  OrganizationMember[]
  auditEntries AdminAuditLog[]

  @@map("admin_users")
}

enum OrganizationRole {
  OWNER
  ADMIN
  FORM_EDITOR
  ANALYST
  READ_ONLY
}

model OrganizationMember {
  id             String           @id @default(uuid()) @db.Uuid
  organizationId String           @map("organization_id") @db.Uuid
  adminUserId    String           @map("admin_user_id") @db.Uuid
  role           OrganizationRole @default(READ_ONLY)
  createdAt      DateTime         @default(now()) @map("created_at")

  organization   Organization     @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  adminUser      AdminUser        @relation(fields: [adminUserId], references: [id], onDelete: Cascade)

  @@unique([organizationId, adminUserId])
  @@index([adminUserId])
  @@map("organization_members")
}

model AdminAuditLog {
  id           String    @id @default(uuid()) @db.Uuid
  adminUserId  String    @map("admin_user_id") @db.Uuid
  organizationId String  @map("organization_id") @db.Uuid
  action       String    @db.VarChar(100)
  targetType   String    @map("target_type") @db.VarChar(100)
  targetId     String    @map("target_id") @db.VarChar(255)
  metadata     Json      @default("{}")
  createdAt    DateTime  @default(now()) @map("created_at")

  adminUser    AdminUser @relation(fields: [adminUserId], references: [id], onDelete: Cascade)

  @@index([organizationId, createdAt])
  @@index([adminUserId, createdAt])
  @@map("admin_audit_logs")
}
```

Then update the existing `Event` model:

```prisma
model Event {
  id             String       @id @default(uuid()) @db.Uuid
  organizationId String       @map("organization_id") @db.Uuid
  title          String       @db.VarChar(255)
  createdAt      DateTime     @default(now()) @map("created_at")

  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  sessions       Session[]

  @@index([organizationId])
  @@map("events")
}
```

---

## H.5 Why organization ID belongs on the event

You may wonder why the organization belongs to the `Event` record instead of every table.

The relationship already gives us a secure chain:

```text
Organization
  ↓
Event
  ↓
Session
  ↓
FormVersion / Response / Report
```

When an administrator requests a session, the application can verify ownership through that relationship.

Example secure Prisma query:

```ts
const session = await prisma.session.findFirst({
  where: {
    id: sessionId,
    event: {
      organizationId: authenticatedUser.organizationId,
    },
  },
});
```

This prevents an administrator from simply changing the URL:

```text
/admin/sessions/ACME-SESSION
```

to:

```text
/admin/sessions/NORTHWIND-SESSION
```

and accessing another organization’s data.

---

## H.6 Role-based access control

**Role-based access control**, often shortened to RBAC, means each administrator receives only the permissions needed for their job.

A recommended role model is:

| Role | Typical permissions |
|---|---|
| `OWNER` | Manage organization, users, billing, all events, and deletion |
| `ADMIN` | Manage events, forms, sessions, exports, and reports |
| `FORM_EDITOR` | Create and edit events, sessions, and form drafts |
| `ANALYST` | View analytics, export CSV, request reports |
| `READ_ONLY` | View dashboards and completed reports only |

Example permission matrix:

| Action | Owner | Admin | Form Editor | Analyst | Read Only |
|---|:---:|:---:|:---:|:---:|:---:|
| Create event | Yes | Yes | Yes | No | No |
| Create session | Yes | Yes | Yes | No | No |
| Edit draft form | Yes | Yes | Yes | No | No |
| Publish form | Yes | Yes | Yes | No | No |
| Close session | Yes | Yes | Yes | No | No |
| View analytics | Yes | Yes | Yes | Yes | Yes |
| Export CSV | Yes | Yes | No | Yes | No |
| Generate PDF | Yes | Yes | No | Yes | No |
| Invite users | Yes | Yes | No | No | No |
| Delete organization | Yes | No | No | No | No |

---

## H.7 Authorization helper example

A future authorization helper should verify both authentication and permission.

### `src/lib/authorization.ts`

```ts
import "server-only";

import { OrganizationRole } from "@prisma/client";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";

type CurrentAdmin = {
  userId: string;
  organizationId: string;
  role: OrganizationRole;
};

/**
 * In a production application, this function would read a signed login
 * session and return the authenticated administrator's identity.
 */
export async function getCurrentAdmin(): Promise<CurrentAdmin | null> {
  return null;
}

export async function requireOrganizationRole(
  allowedRoles: OrganizationRole[],
): Promise<CurrentAdmin> {
  const currentAdmin = await getCurrentAdmin();

  if (!currentAdmin) {
    redirect("/admin/login");
  }

  if (!allowedRoles.includes(currentAdmin.role)) {
    redirect("/admin/forbidden");
  }

  return currentAdmin;
}

export async function requireSessionAccess(
  sessionId: string,
  allowedRoles: OrganizationRole[],
) {
  const currentAdmin = await requireOrganizationRole(allowedRoles);

  const session = await prisma.session.findFirst({
    where: {
      id: sessionId,
      event: {
        organizationId: currentAdmin.organizationId,
      },
    },
    select: {
      id: true,
      title: true,
      eventId: true,
    },
  });

  if (!session) {
    redirect("/admin/not-found");
  }

  return {
    currentAdmin,
    session,
  };
}
```

This helper would be used before loading a session editor or dashboard.

Example:

```ts
const { currentAdmin, session } = await requireSessionAccess(sessionId, [
  OrganizationRole.OWNER,
  OrganizationRole.ADMIN,
  OrganizationRole.FORM_EDITOR,
]);
```

---

## H.8 Audit logging

An audit log records important administrator actions.

This is useful when someone asks:

```text
Who published this form?
When was this session closed?
Who exported participant responses?
Who deleted a report?
```

Recommended actions include:

```text
organization.created
organization.member.invited
organization.member.role_changed
event.created
event.updated
session.created
session.closed
session.reopened
form.draft_created
form.question_added
form.question_deleted
form.version_published
csv.exported
report.requested
report.downloaded
report.deleted
```

Example audit log function:

### `src/lib/audit-log.ts`

```ts
import "server-only";

import { prisma } from "@/lib/prisma";

type CreateAuditLogInput = {
  adminUserId: string;
  organizationId: string;
  action: string;
  targetType: string;
  targetId: string;
  metadata?: Record<string, unknown>;
};

export async function createAuditLog(
  input: CreateAuditLogInput,
): Promise<void> {
  await prisma.adminAuditLog.create({
    data: {
      adminUserId: input.adminUserId,
      organizationId: input.organizationId,
      action: input.action,
      targetType: input.targetType,
      targetId: input.targetId,
      metadata: input.metadata ?? {},
    },
  });
}
```

Example use after publishing a form:

```ts
await createAuditLog({
  adminUserId: currentAdmin.userId,
  organizationId: currentAdmin.organizationId,
  action: "form.version_published",
  targetType: "form_version",
  targetId: formVersion.id,
  metadata: {
    sessionId,
    versionNumber: formVersion.versionNumber,
  },
});
```

Do not store raw participant feedback text in audit logs.

---

## H.9 Session ID strategy for multiple organizations

The tutorial uses globally unique session IDs:

```text
REACT-2026-Q3
TYPESCRIPT-MODULE-1
```

This works well because a participant route can remain simple:

```text
/e/REACT-2026-Q3
```

In a multi-tenant environment, you have two common approaches.

## Option 1: Keep session IDs globally unique

```text
/e/ACME-REACT-2026-Q3
/e/NORTHWIND-REACT-2026-Q3
```

Advantages:

```text
Simple public route.
Simple database lookup.
No tenant URL segment required.
```

Disadvantages:

```text
Organizations must coordinate or prefix IDs.
IDs can become longer.
```

## Option 2: Use organization slug and session ID

```text
/e/acme-training/REACT-2026-Q3
/e/northwind-university/REACT-2026-Q3
```

Advantages:

```text
Each organization can reuse short session IDs.
URLs make organization ownership visible.
```

Disadvantages:

```text
More complex routing.
More complex QR URLs.
```

A corresponding Next.js route would be:

```text
src/app/e/[organizationSlug]/[sessionId]/page.tsx
```

For most multi-organization deployments, Option 2 is clearer and more scalable.

---

## H.10 Scaling analytics

The tutorial dashboard calculates analytics directly from responses and answers.

That is ideal when:

```text
Small to medium session response volume.
Reports generated occasionally.
Simplicity and accuracy are primary goals.
```

As volume grows, consider these thresholds.

| Approximate workload | Recommended strategy |
|---|---|
| Under 10,000 responses per session | Direct calculation is usually acceptable |
| 10,000–100,000 responses per session | Add pagination, indexes, and summary queries |
| Above 100,000 responses per session | Consider aggregate tables or analytics warehouse |
| Many concurrent dashboard viewers | Cache dashboard summaries |
| Frequent real-time dashboards | Add event-driven aggregate updates |

---

## H.11 Database indexes for larger deployments

The tutorial schema already includes useful indexes such as:

```text
Response(sessionId, submittedAt)
Response(formVersionId)
Answer(questionId)
FormVersion(sessionId, status)
```

For larger deployments, analyze real query patterns before adding indexes.

Potential future indexes:

```prisma
model Response {
  // Existing fields omitted.

  @@index([sessionId, formVersionId, submittedAt])
  @@index([submittedAt])
}

model Report {
  // Existing fields omitted.

  @@index([sessionId, status, createdAt])
}
```

Do not add indexes blindly. Every index improves some reads but adds overhead to writes.

Use Neon query monitoring, PostgreSQL `EXPLAIN ANALYZE`, and real application metrics to decide.

---

## H.12 Aggregate tables for high-volume dashboards

At high scale, calculating every metric from raw answers repeatedly may become expensive.

A future aggregate model could look like:

```text
SessionAnalyticsSnapshot
├── sessionId
├── formVersionId
├── totalResponses
├── averageRating
├── primaryNps
├── calculatedAt
└── metrics JSON
```

Or more normalized:

```text
QuestionAggregate
├── questionId
├── responseCount
├── numericSum
├── numericMinimum
├── numericMaximum
└── updatedAt

QuestionOptionAggregate
├── questionId
├── optionValue
├── count
└── updatedAt
```

Inngest could update these records after each submission:

```text
feedback/submitted
        ↓
Save response
        ↓
Update question aggregates
        ↓
Refresh dashboard cache
```

This design improves dashboard speed but adds complexity:

```text
Aggregate update failures.
Retry safety.
Backfill requirements.
Recalculation after bugs.
Version handling.
```

Use it only when measured performance needs justify it.

---

## H.13 Scheduled maintenance jobs

As GreyMatter Feedback grows, scheduled background jobs become useful.

Examples:

```text
Nightly IP hash cleanup.
Monthly report retention cleanup.
Daily analytics snapshot generation.
Closed-session reminders.
Unpublished draft reminders.
Expired report deletion.
```

Example Inngest cron function:

```ts
import { inngest } from "@/inngest/client";

export const cleanExpiredMetadata = inngest.createFunction(
  {
    id: "clean-expired-response-metadata",
  },
  {
    cron: "0 3 * * *",
  },
  async ({ step }) => {
    await step.run("remove-old-ip-hashes", async () => {
      // Implement a retention-policy cleanup query here.
    });

    return {
      status: "complete",
    };
  },
);
```

Before adding a cleanup job, define:

```text
What data expires?
How long is it retained?
Who approves retention periods?
Can cleanup be reversed?
Are backups affected?
```

---

## H.14 Recommended SaaS deployment boundaries

For a full software-as-a-service, or **SaaS**, version of GreyMatter Feedback, separate environments.

```text
Development
├── Neon development branch
├── Inngest development app
├── Upstash development database
└── Development report bucket/prefix

Staging
├── Neon staging branch
├── Inngest staging app
├── Upstash staging database
└── Staging report bucket/prefix

Production
├── Neon production branch
├── Inngest production app
├── Upstash production database
└── Production report bucket/prefix
```

Never share production secrets or production databases with local development.

---

## H.15 Multi-tenant readiness checklist

Before offering GreyMatter Feedback to multiple organizations, verify:

```text
[ ] Every event belongs to an organization.
[ ] Every admin request is scoped to an organization.
[ ] Session editor queries verify organization ownership.
[ ] Analytics queries verify organization ownership.
[ ] CSV exports verify organization ownership.
[ ] PDF report requests verify organization ownership.
[ ] Report downloads verify organization ownership.
[ ] Administrators have individual accounts.
[ ] Passwords are hashed using a modern algorithm.
[ ] Roles limit access appropriately.
[ ] Audit logs record sensitive administrative actions.
[ ] Organization data is isolated in tests.
[ ] Deleted organizations remove or retain data according to policy.
[ ] Billing and plan limits are defined if applicable.
```

---

## H.16 Recommended upgrade order

If you are evolving the tutorial project into a multi-organization product, use this order:

```text
1. Replace shared admin password with individual admin users.
2. Add password hashing and secure login sessions.
3. Add Organization and OrganizationMember models.
4. Associate events with organizations.
5. Scope every admin query by organization.
6. Add role-based permissions.
7. Add audit logs.
8. Protect report downloads with signed URLs.
9. Add separate staging infrastructure.
10. Measure performance before adding aggregate tables.
```

This order prioritizes security and data isolation before advanced scale optimizations.
