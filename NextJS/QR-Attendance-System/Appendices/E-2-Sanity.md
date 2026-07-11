# Appendix E.2

## File: `src/lib/sanity/client.ts`

**Purpose**

This module creates the application's Sanity clients.

Rather than creating clients throughout the application, a single module owns the connection configuration and exports appropriately configured clients for reading and writing content.

Following this pattern provides:

* centralized configuration
* consistent authentication
* easier testing
* cleaner dependency injection
* simpler future upgrades

---

### Source Code

```typescript
/**
 * ============================================================================
 * File: src/lib/sanity/client.ts
 * ----------------------------------------------------------------------------
 * Shared Sanity clients for the Attendance Platform.
 *
 * All repositories should import clients from this module.
 * Never call createClient() anywhere else.
 * ============================================================================
 */

import { createClient } from "next-sanity";
import { env } from "@/lib/config/env";

/**
 * ----------------------------------------------------------------------------
 * Shared Configuration
 * ----------------------------------------------------------------------------
 */

const config = {
  projectId: env.SANITY_PROJECT_ID,

  dataset: env.SANITY_DATASET,

  apiVersion: env.SANITY_API_VERSION,

  useCdn: env.NODE_ENV === "production",

  perspective: "published" as const,
};

/**
 * ----------------------------------------------------------------------------
 * Public Read Client
 * ----------------------------------------------------------------------------
 *
 * Used by:
 *
 * • Server Components
 * • Public event pages
 * • Dashboard queries
 *
 * Does NOT require authentication.
 */

export const sanityReadClient = createClient({
  ...config,
});

/**
 * ----------------------------------------------------------------------------
 * Authenticated Write Client
 * ----------------------------------------------------------------------------
 *
 * Used by:
 *
 * • Repositories
 * • Server Actions
 * • Inngest Workflows
 *
 * Supports document creation,
 * updates,
 * patches,
 * and transactions.
 */

export const sanityWriteClient = createClient({
  ...config,

  token: env.SANITY_API_TOKEN,

  useCdn: false,
});

/**
 * ----------------------------------------------------------------------------
 * Preview Client
 * ----------------------------------------------------------------------------
 *
 * Used only for Draft Mode.
 */

export const sanityPreviewClient = createClient({
  ...config,

  token: env.SANITY_API_TOKEN,

  perspective: "previewDrafts",

  useCdn: false,
});

/**
 * ----------------------------------------------------------------------------
 * Helper
 * ----------------------------------------------------------------------------
 */

export function getSanityClient(options?: {
  preview?: boolean;
  write?: boolean;
}) {
  if (options?.write) {
    return sanityWriteClient;
  }

  if (options?.preview) {
    return sanityPreviewClient;
  }

  return sanityReadClient;
}
```

---

## Why Three Clients?

Separating clients prevents accidental privilege escalation.

| Client                | Purpose                | Token Required |
| --------------------- | ---------------------- | -------------- |
| `sanityReadClient`    | Public read operations | No             |
| `sanityWriteClient`   | Create, update, delete | Yes            |
| `sanityPreviewClient` | Draft Mode previews    | Yes            |

This separation also makes security reviews much easier because write operations always originate from the authenticated client.

---

## Typical Usage

### Server Component

```typescript
import { sanityReadClient } from "@/lib/sanity/client";

const event = await sanityReadClient.fetch(EVENT_QUERY, {
  slug,
});
```

---

### Repository

```typescript
import { sanityWriteClient } from "@/lib/sanity/client";

await sanityWriteClient.create(document);
```

---

### Draft Mode

```typescript
const client = getSanityClient({
  preview: true,
});

const draft = await client.fetch(query);
```

---

## Design Decisions

### Read and Write Separation

The application deliberately avoids a single "super client."

Repositories performing writes should explicitly import the write client, making persistence operations easy to identify during code reviews.

---

### CDN Usage

Public content can safely use Sanity's global CDN.

Workflow writes, attendance records, and administrative operations should always bypass the CDN to ensure strong consistency.

---

### Preview Isolation

Draft content should never be exposed accidentally.

Using a dedicated preview client keeps preview logic isolated from production rendering.

---

### Single Factory

The `getSanityClient()` helper provides flexibility for future enhancements, such as tenant-specific datasets or custom authentication strategies, while keeping most callers simple.

---

## Repository Dependency

The rest of the application should interact with Sanity through repositories rather than directly through these clients.

```text
Server Component
        │
        ▼
Repository
        │
        ▼
sanityReadClient

────────────────────────────

Server Action
        │
        ▼
Repository
        │
        ▼
sanityWriteClient

────────────────────────────

Draft Mode
        │
        ▼
Repository
        │
        ▼
sanityPreviewClient
```

Keeping client creation centralized ensures consistent behavior throughout the application and makes infrastructure changes significantly easier.
