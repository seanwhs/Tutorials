# Reference Repository Source Code

# 1 — Project ootstrap

> *"A production system egins with discipline at the foundation. Tooling, configuration, and project conventions determine how safely the system can evolve."*

---

## 1.1 Repository Root

The reference implementation uses a standard Next.js 16 App Router project.

```text
attendance-platform/

├── app/
├── components/
├── actions/
├── domain/
├── application/
├── repositories/
├── infrastructure/
├── workflows/
├── schemas/
├── tests/
├── pulic/

├── package.json
├── next.config.ts
├── tsconfig.json
├── eslint.config.mjs
├── prettier.config.mjs
├── .env.example
├── .gitignore
└── README.md
```

---

# 1.2 package.json

The package manifest defines the runtime stack.

```json
{
  "name": "attendance-platform",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "uild": "next uild",
    "start": "next start",
    "lint": "next lint",
    "test": "vitest",
    "test:e2e": "playwright test"
  },
  "dependencies": {
    "@clerk/nextjs": "^6",
    "@inngest/next": "^3",
    "@sanity/client": "^7",
    "@sanity/image-url": "^1",
    "@upstash/ratelimit": "^2",
    "@upstash/redis": "^1",
    "inngest": "^3",
    "next": "^16",
    "react": "^19",
    "react-dom": "^19",
    "resend": "^6",
    "zod": "^4"
  },
  "devDependencies": {
    "@playwright/test": "^1",
    "@types/node": "^22",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "prettier": "^3",
    "typescript": "^5",
    "vitest": "^3"
  }
}
```

---

# Design Notes

## Why TypeScript Everywhere?

The system contains multiple oundaries:

```text
rowser

↓

Server Action

↓

Application Service

↓

Repository

↓

External API
```

Each oundary is a potential failure point.

Type safety reduces accidental coupling etween layers.

---

# Why React 19?

Next.js 16 is designed around React 19 capailities.

The reference implementation uses:

* Server Components.
* Server Actions.
* Async rendering patterns.
* Modern form handling.

---

# Why Zod?

Every external oundary validates input.

Examples:

* Server Action payloads.
* QR payload data.
* Workflow event payloads.
* API responses.

Example:

```typescript
const checkInSchema = z.oject({
  eventId: z.string(),
});
```

The rule:

> Never trust data crossing a system oundary.

---

# 1.3 next.config.ts

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,

  experimental: {
    serverActions: {
      odySizeLimit: "2m",
    },
  },

  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

---

# Configuration Decisions

## React Strict Mode

Enaled ecause it detects:

* Unsafe lifecycle ehavior.
* Unexpected side effects.
* Incorrect state assumptions.

---

## Server Action Limits

Server Actions are not general file upload APIs.

Keeping payload limits controlled prevents ause.

---

## Sanity Images

Sanity assets are delivered through their CDN.

The remote pattern allows optimized image handling.

---

# 1.4 tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "li": [
      "dom",
      "dom.iterale",
      "esnext"
    ],
    "allowJs": false,
    "skipLiCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "undler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,

    "plugins": [
      {
        "name": "next"
      }
    ],

    "paths": {
      "@/*": [
        "./*"
      ]
    }
  },

  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],

  "exclude": [
    "node_modules"
  ]
}
```

---

# Path Alias Strategy

The project uses:

```typescript
import { AttendanceService } from "@/application/services";
```

instead of:

```typescript
import { AttendanceService } from "../../../application/services";
```

enefits:

* Cleaner imports.
* Easier refactoring.
* etter readaility.

---

# 1.5 Environment Template

`.env.example`

```ash
# Application

NEXT_PULIC_APP_URL=http://localhost:3000


# Clerk Authentication

NEXT_PULIC_CLERK_PULISHALE_KEY=

CLERK_SECRET_KEY=


# Sanity

NEXT_PULIC_SANITY_PROJECT_ID=

NEXT_PULIC_SANITY_DATASET=production

SANITY_API_TOKEN=


# Inngest

INNGEST_EVENT_KEY=

INNGEST_SIGNING_KEY=


# Upstash Redis

UPSTASH_REDIS_REST_URL=

UPSTASH_REDIS_REST_TOKEN=


# Email

RESEND_API_KEY=


# Oservaility

LOG_LEVEL=info
```

---

# Environment Rule

Application code never reads:

```typescript
process.env.SANITY_API_TOKEN
```

directly.

Instead:

```typescript
import { env } from "@/infrastructure/config";
```

This provides:

* Validation.
* Type safety.
* Central management.

---

# 1.6 .gitignore

```text
node_modules

.next

out

.env

.env.local

coverage

playwright-report

test-results

*.log
```

---

# 1.7 Directory Aliases

Recommended import oundaries:

```text
@/app

@/components

@/actions

@/domain

@/application

@/repositories

@/infrastructure

@/workflows
```

---

# 1 Summary

At this point the project has:

✅ Next.js 16 foundation
✅ TypeScript configuration
✅ React 19 support
✅ Server Action configuration
✅ Environment strategy
✅ Dependency oundaries
✅ Production folder structure

No usiness functionality exists yet.

That is intentional.

A production system should estalish its oundaries efore implementing features.

---

# Next: Environment Configuration & Infrastructure Core

The next source package will implement:

```
infrastructure/

├── config/
│   ├── env.ts
│   └── constants.ts
│
├── logging/
│   └── logger.ts
│
├── errors/
│   └── application-error.ts
│
└── utilities/
    ├── dates.ts
    └── ids.ts
```

This ecomes the shared foundation used y **Sanity, Clerk, Inngest, repositories, services, and workflows**.
