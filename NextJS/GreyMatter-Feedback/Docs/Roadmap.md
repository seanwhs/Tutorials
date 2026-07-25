# GreyMatter Feedback Product and Technical Roadmap

**Authentication Enhancement:** Replace the planned custom named-user authentication implementation with **Clerk**.

Clerk will become the recommended authentication and user-management provider for future GreyMatter Feedback releases.

---

## Roadmap Overview

| Phase | Timeframe | Theme | Primary Outcome |
|---|---|---|---|
| Phase 0 | Complete | Core foundation | QR feedback, versioned forms, analytics, CSV, PDF |
| Phase 1 | 0–3 months | Production hardening | Private reports, monitoring, retention, stronger operations |
| Phase 2 | 3–6 months | Better authoring | Templates, question library, previews, reusable forms |
| Phase 3 | 6–9 months | Clerk authentication and governance | Named users, MFA, roles, organizations, auditability |
| Phase 4 | 9–12 months | Multi-organization platform | Tenant isolation, branding, organization-scoped data |
| Phase 5 | 12–18 months | Integrations and scale | Notifications, webhooks, imports, advanced analytics |
| Phase 6 | 18–24 months | Intelligence and enterprise readiness | AI summaries, SSO, governance, enterprise controls |

---

# Phase 0 — Core Product Foundation

**Status:** Complete  
**Release:** Version 1.0

Current baseline authentication uses:

```text
Single administrator password
Signed HTTP-only session cookie
ADMIN_PASSWORD
ADMIN_SESSION_SECRET
```

This is suitable for:

```text
Local development
Prototype deployments
Small internal teams
Single-operator environments
```

It is not the recommended long-term production authentication model.

---

# Phase 1 — Production Hardening and Operational Reliability

**Timeframe:** Months 0–3  
**Suggested Release:** Version 1.1

## Priorities

```text
Private PDF report storage
Protected signed PDF downloads
Admin login rate limiting
Security headers
Error monitoring and alerts
Scheduled privacy cleanup
Recovery drills
```

## Clerk Preparation Work

Although Clerk is introduced in Phase 3, Phase 1 should prepare the application for the migration.

### Required changes

```text
[ ] Isolate current admin authorization helpers.
[ ] Avoid spreading custom cookie logic across route files.
[ ] Create a single requireAdmin() abstraction.
[ ] Create a single getCurrentAdmin() abstraction.
[ ] Ensure export and report APIs use centralized authorization checks.
[ ] Add audit-friendly action identifiers for publish, export, and report actions.
```

This makes replacement easier later.

---

# Phase 2 — Better Form Authoring

**Timeframe:** Months 3–6  
**Suggested Release:** Version 1.2

## Priorities

```text
Form templates
Question library
Question helper text
Improved draft preview
Duplicate session workflow
CSV session import
```

## Clerk Dependency

No Clerk dependency is required for this phase, but new authoring routes must continue using centralized authorization helpers.

```text
Do not hard-code ADMIN_PASSWORD checks inside authoring actions.
Do not access custom session cookie directly inside page components.
Use requireAdmin() or equivalent centralized helper.
```

---

# Phase 3 — Clerk Authentication, Organizations, Roles, and Governance

**Timeframe:** Months 6–9  
**Suggested Release:** Version 1.5

## Objective

Replace the baseline shared-password administrator authentication model with Clerk-managed user authentication and organization-aware access control.

---

## 3.1 Clerk Integration

Clerk will provide:

```text
Administrator sign-in
Administrator sign-out
User session management
Secure session cookies
Multi-factor authentication
Email verification
Password reset workflow
Social login, if enabled
Organization support
User profile management
Session revocation
```

The custom baseline components become deprecated:

```text
ADMIN_PASSWORD
ADMIN_SESSION_SECRET
src/lib/admin-auth.ts custom HMAC session logic
/admin/login custom password form
```

---

## 3.2 Updated Authentication Architecture

```text
Administrator Browser
        ↓
Clerk Sign In
        ↓
Clerk Session
        ↓
Next.js Middleware / Server Authorization
        ↓
GreyMatter Admin Routes
        ↓
Neon PostgreSQL Data Access
```

### Clerk integration pattern

```text
Clerk
├── User identity
├── Authentication
├── MFA
├── Session handling
└── Organization membership

GreyMatter Feedback
├── Event ownership
├── Session ownership
├── Form version ownership
├── Analytics authorization
├── Report authorization
└── Domain-specific audit log
```

Clerk manages identity. GreyMatter Feedback manages product-specific data and permissions.

---

## 3.3 Clerk Technical Requirements

Recommended packages:

```bash
npm install @clerk/nextjs
```

Required environment variables:

```dotenv
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_..."
CLERK_SECRET_KEY="sk_..."
CLERK_SIGN_IN_URL="/sign-in"
CLERK_SIGN_UP_URL="/sign-up"
CLERK_AFTER_SIGN_IN_URL="/admin/events"
CLERK_AFTER_SIGN_UP_URL="/admin/events"
```

Recommended protected route pattern:

```text
Public:
/
 /e/*
 /api/feedback
 /api/inngest

Protected:
 /admin/*
 /api/admin/*
```

---

## 3.4 Replace Baseline Admin Login

Current baseline route:

```text
/admin/login
```

Recommended Clerk routes:

```text
/sign-in
/sign-up
```

The application may preserve the old route for compatibility:

```text
/admin/login
        ↓ redirect
/sign-in
```

### Migration requirements

```text
[ ] Add ClerkProvider to root layout.
[ ] Add Clerk middleware.
[ ] Define public route matcher.
[ ] Protect /admin routes.
[ ] Protect /api/admin routes.
[ ] Replace custom login page with Clerk SignIn component.
[ ] Replace custom logout action with Clerk UserButton or sign-out flow.
[ ] Remove ADMIN_PASSWORD from production environment.
[ ] Remove ADMIN_SESSION_SECRET from production environment.
```

---

## 3.5 Role-Based Access with Clerk Organizations

Clerk Organizations should become the identity and membership layer for multi-organization GreyMatter Feedback.

Suggested Clerk organization roles:

| Clerk Role | GreyMatter Meaning |
|---|---|
| `org:admin` | Organization owner or full administrator |
| `org:form_editor` | Can create sessions and edit draft forms |
| `org:analyst` | Can view analytics, export CSV, and request reports |
| `org:viewer` | Can view dashboards and completed reports |

Recommended permission model:

| Action | Admin | Form Editor | Analyst | Viewer |
|---|:---:|:---:|:---:|:---:|
| Create event | Yes | Yes | No | No |
| Create session | Yes | Yes | No | No |
| Edit draft form | Yes | Yes | No | No |
| Publish form | Yes | Yes | No | No |
| Close session | Yes | Yes | No | No |
| View analytics | Yes | Yes | Yes | Yes |
| Export CSV | Yes | No | Yes | No |
| Generate PDF | Yes | No | Yes | No |
| Manage members | Yes | No | No | No |

---

## 3.6 Clerk and Neon Data Model

Clerk should remain the source of truth for authentication identities and organization memberships.

Neon should store the GreyMatter domain relationship.

Recommended schema additions:

```prisma
model Organization {
  id          String   @id @default(uuid()) @db.Uuid
  clerkOrgId  String   @unique @map("clerk_org_id") @db.VarChar(255)
  name        String   @db.VarChar(255)
  slug        String   @unique @db.VarChar(100)
  createdAt   DateTime @default(now()) @map("created_at")

  events      Event[]

  @@map("organizations")
}

model AdminAuditLog {
  id             String   @id @default(uuid()) @db.Uuid
  clerkUserId    String   @map("clerk_user_id") @db.VarChar(255)
  organizationId String   @map("organization_id") @db.Uuid
  action         String   @db.VarChar(100)
  targetType     String   @map("target_type") @db.VarChar(100)
  targetId       String   @map("target_id") @db.VarChar(255)
  metadata       Json     @default("{}")
  createdAt      DateTime @default(now()) @map("created_at")

  @@index([organizationId, createdAt])
  @@index([clerkUserId, createdAt])
  @@map("admin_audit_logs")
}
```

Update `Event`:

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

## 3.7 Clerk Authorization Flow

```text
Administrator signs in with Clerk
        ↓
Clerk identifies user and active organization
        ↓
Next.js server reads Clerk auth context
        ↓
GreyMatter verifies active Clerk organization
        ↓
GreyMatter queries Neon using organization scope
        ↓
Administrator accesses only organization-owned events and sessions
```

Example secure query principle:

```ts
const event = await prisma.event.findFirst({
  where: {
    id: eventId,
    organization: {
      clerkOrgId: activeOrganizationId,
    },
  },
});
```

This prevents changing a route from:

```text
/admin/events/acme-event-id
```

to:

```text
/admin/events/another-organization-event-id
```

and accessing another organization’s data.

---

## 3.8 Clerk Audit Logging

Clerk provides identity and organization context. GreyMatter should log domain actions separately.

Examples:

```text
event.created
session.created
session.closed
form.draft_created
form.question_added
form.version_published
csv.exported
report.requested
report.downloaded
member.role_changed
```

Each audit record should include:

```text
Clerk user ID
Clerk organization ID or GreyMatter organization ID
Action
Target type
Target ID
Timestamp
Safe metadata
```

Do not place raw participant comments in audit metadata.

---

## Phase 3 Success Criteria

```text
[ ] Clerk is integrated into Next.js application.
[ ] /admin routes require Clerk authentication.
[ ] /api/admin routes require Clerk authentication.
[ ] Custom ADMIN_PASSWORD production workflow is removed.
[ ] Custom HMAC admin session logic is removed.
[ ] Clerk MFA is enabled for privileged administrators.
[ ] Clerk Organizations are enabled.
[ ] Organization roles are enforced.
[ ] Event, session, report, and export queries are organization-scoped.
[ ] Audit logs record sensitive administrator actions.
```

---

# Phase 4 — Multi-Organization Platform

**Timeframe:** Months 9–12  
**Suggested Release:** Version 2.0

## Updated Objective

Use Clerk Organizations as the identity and membership layer while Neon stores GreyMatter-specific organization data.

```text
Clerk Organization
        ↓
GreyMatter Organization record
        ↓
Events
        ↓
Sessions
        ↓
Forms, responses, reports
```

## Priorities

```text
Organization onboarding
Organization branding
Organization-specific form templates
Organization-scoped reporting
Organization-scoped storage prefixes
Tenant-aware QR URL strategy
Organization member management through Clerk
```

## Recommended QR URL Pattern

```text
/e/[organizationSlug]/[sessionId]
```

Example:

```text
/e/acme-training/REACT-2026-Q3
```

---

# Phase 5 — Integrations and Scale

**Timeframe:** Months 12–18  
**Suggested Release:** Version 2.5

No major authentication architecture changes.

All integrations must use Clerk identity and organization context where relevant.

Examples:

```text
Report-ready email sent to authorized Clerk user.
Slack webhook configured per Clerk organization.
Outbound webhook belongs to one organization.
CSV session import is scoped to active organization.
Audit log records integration configuration changes.
```

---

# Phase 6 — Enterprise Readiness

**Timeframe:** Months 18–24  
**Suggested Release:** Version 3.0

Clerk can support enterprise identity expansion.

Potential features:

```text
Enterprise SSO
SAML
OpenID Connect
SCIM provisioning
Domain verification
Organization-level MFA enforcement
Session management policies
Enterprise audit export
```

---

# Updated Immediate Next Priorities

```text
1. Private signed PDF report downloads
2. Centralized authorization abstraction to prepare for Clerk
3. Clerk authentication integration
4. Clerk Organizations and organization-scoped data access
5. Clerk-based roles and permissions
6. Domain-specific audit logs
7. Form templates
```

---

# Deprecated Future Work

The following roadmap items are replaced by Clerk capabilities:

| Previous Plan | Updated Plan |
|---|---|
| Build custom named admin user table | Use Clerk User identities |
| Build custom password hashing flow | Use Clerk-managed passwords and authentication |
| Build custom password reset | Use Clerk password reset |
| Build custom email verification | Use Clerk verification |
| Build custom MFA | Use Clerk MFA |
| Build custom session revocation | Use Clerk session management |
| Build custom organization membership | Use Clerk Organizations |
| Build custom user invitations | Use Clerk organization invitations where suitable |

GreyMatter Feedback should still maintain its own:

```text
Organization domain record
Event ownership
Session ownership
Form ownership
Report ownership
Audit log
Domain-specific permissions
Data retention policy
```

Clerk manages identity; GreyMatter Feedback manages feedback product data.
