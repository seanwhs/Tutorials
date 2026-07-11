# Project Bootstrap

> *"A production system begins with discipline at the foundation. Tooling, configuration, and project conventions determine how safely the system can evolve."*

---

## 1.1 Repository Root

The reference implementation is a standard Next.js 16 App Router project, structured to enforce clean architectural boundaries.

```text
attendance-platform/
├── app/            # Next.js App Router
├── components/     # UI and presentation logic
├── actions/        # Server Actions
├── domain/         # Business logic (Agnostic)
├── application/    # Orchestration and services
├── repositories/   # Data persistence
├── infrastructure/ # External system adapters
├── workflows/      # Durable processes
├── schemas/        # Zod validation schemas
├── tests/          # Test suites
├── public/         # Static assets
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

## 1.2 package.json

The project utilizes modern React 19 and Next.js 16 standards, with Zod for runtime type safety at system boundaries.

```json
{
  "name": "attendance-platform",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
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
  }
}

```

### Design Principles

* **TypeScript:** Enforces strict contracts across architectural layers, mitigating failure at system boundaries.
* **React 19:** Leverages server-side primitives and modern form handling.
* **Zod:** Mandates runtime validation for all data traversing system boundaries (e.g., QR payloads, API responses). *Rule: Never trust untyped data crossing a boundary.*

---

## 1.3 next.config.ts

Configuration emphasizes security and asset optimization.

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  experimental: {
    serverActions: {
      bodySizeLimit: "2mb",
    },
  },
  images: {
    remotePatterns: [{ protocol: "https", hostname: "cdn.sanity.io" }],
  },
};

export default nextConfig;

```

* **Strict Mode:** Enabled to detect side effects and unsafe lifecycle behavior.
* **Action Limits:** Payload size is restricted to prevent abuse of Server Actions.

---

## 1.4 tsconfig.json

Path aliasing is implemented to ensure cleaner imports and simpler refactoring.

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "strict": true,
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"]
}

```

* **Import Strategy:** Use `@/application/services` instead of relative paths (e.g., `../../../`) to maintain architectural clarity.

---

## 1.5 Environment Template (`.env.example`)

Centralized management ensures all secrets are accounted for. **Crucially: Application code never accesses `process.env` directly.**

```bash
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_SANITY_PROJECT_ID=
SANITY_API_TOKEN=
INNGEST_EVENT_KEY=
# ... etc

```

* **Pattern:** Access configuration via an internal `infrastructure/config` module that provides validation and type safety.

---

## 1.6 Summary

The project foundation is now established:

* ✅ Next.js 16 & React 19 baseline.
* ✅ TypeScript configuration and path aliasing.
* ✅ Boundary validation strategy (Zod).
* ✅ Secure environment handling.
* ✅ Folder structure mapping.

No business functionality exists yet; this is intentional. Establishing rigorous boundaries before implementing features ensures that the system can evolve without architectural drift.

---

## Next: Infrastructure Core

The next module will implement the shared infrastructure foundation:

* `infrastructure/config/`: Environment validation.
* `infrastructure/logging/`: Centralized observability.
* `infrastructure/errors/`: Standardized application error handling.
* `infrastructure/utilities/`: Shared date and ID generation logic.
