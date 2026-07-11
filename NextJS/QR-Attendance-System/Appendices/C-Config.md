# Appendix C

# Project Bootstrap and Configuration

> *"Every production application begins long before the first page component is written. The bootstrap layer establishes the project's standards, tooling, build process, and runtime configuration."*

---

# Purpose

This appendix presents the complete bootstrap configuration for the QR Attendance Platform.

These files define:

* project dependencies
* TypeScript configuration
* Next.js configuration
* Tailwind CSS integration
* linting
* environment variables
* middleware registration
* build tooling

Although these files rarely contain business logic, they establish the engineering foundation upon which the entire application is built.

---

# Directory

```text
attendance-platform/

├── .env.example
├── .gitignore
├── components.json
├── eslint.config.mjs
├── middleware.ts
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tailwind.config.ts
├── tsconfig.json
└── README.md
```

---

# File Dependency Diagram

```text
package.json
      │
      ▼
 Next.js
      │
      ├────────► TypeScript
      │
      ├────────► Tailwind
      │
      ├────────► ESLint
      │
      ├────────► Clerk
      │
      ├────────► Sanity
      │
      ├────────► Inngest
      │
      ├────────► Resend
      │
      └────────► Upstash Redis
```

---

# package.json

The package manifest defines the application's runtime dependencies, development tooling, and scripts.

A production application should keep scripts predictable and self-documenting.

```json
{
  "name": "attendance-platform",

  "version": "1.0.0",

  "private": true,

  "type": "module",

  "scripts": {

    "dev": "next dev",

    "build": "next build",

    "start": "next start",

    "lint": "eslint .",

    "typecheck": "tsc --noEmit",

    "test": "vitest",

    "test:watch": "vitest --watch",

    "test:e2e": "playwright test",

    "format": "prettier --write .",

    "check": "npm run lint && npm run typecheck",

    "inngest:dev": "inngest-cli dev",

    "sanity": "sanity",

    "prepare": "husky install"

  },

  "dependencies": {

    "@clerk/nextjs": "^6",

    "@portabletext/react": "^4",

    "@sanity/client": "^7",

    "@sanity/image-url": "^1",

    "@upstash/ratelimit": "^2",

    "@upstash/redis": "^1",

    "inngest": "^3",

    "next": "^16",

    "react": "^19",

    "react-dom": "^19",

    "react-email": "^4",

    "resend": "^4",

    "sanity": "^4",

    "tailwindcss": "^4",

    "zod": "^4",

    "uuid": "^11"

  },

  "devDependencies": {

    "@playwright/test": "^1",

    "@types/node": "^24",

    "@types/react": "^19",

    "@types/react-dom": "^19",

    "eslint": "^9",

    "eslint-config-next": "^16",

    "husky": "^9",

    "prettier": "^3",

    "typescript": "^5",

    "vitest": "^3"
  }

}
```

---

## Design Notes

Notice that only a small number of libraries are required.

Every dependency should solve a clearly defined problem.

Avoid adding packages simply because they are popular.

Each dependency increases maintenance cost.

---

# tsconfig.json

The project uses strict TypeScript settings.

Strict compilation catches defects during development rather than in production.

```json
{
  "compilerOptions": {

    "target": "ES2024",

    "lib": [

      "DOM",

      "DOM.Iterable",

      "ES2024"

    ],

    "strict": true,

    "noUncheckedIndexedAccess": true,

    "noImplicitOverride": true,

    "noImplicitReturns": true,

    "noFallthroughCasesInSwitch": true,

    "exactOptionalPropertyTypes": true,

    "module": "ESNext",

    "moduleResolution": "Bundler",

    "resolveJsonModule": true,

    "jsx": "preserve",

    "incremental": true,

    "paths": {

      "@/*": [

        "./src/*"

      ]

    }

  },

  "include": [

    "next-env.d.ts",

    "**/*.ts",

    "**/*.tsx"

  ],

  "exclude": [

    "node_modules"
  ]
}
```

---

# next.config.ts

The Next.js configuration remains intentionally minimal.

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {

  reactCompiler: true,

  experimental: {

    serverActions: {

      bodySizeLimit: "2mb"

    }

  }

};

export default nextConfig;
```

As a rule, prefer framework defaults unless a measurable need exists to override them.

---

# middleware.ts

Middleware executes before routing and provides a convenient location for authentication and request preprocessing.

Initially, the application delegates authentication to Clerk.

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {

  matcher: [

    "/((?!_next|.*\\..*).*)"

  ]

};
```

Subsequent appendices expand this middleware to include correlation IDs, security headers, and rate limiting.

---

# .env.example

Every required environment variable should be documented.

Never commit production secrets.

```text
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=

CLERK_SECRET_KEY=

NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in

NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up

SANITY_PROJECT_ID=

SANITY_DATASET=

SANITY_API_TOKEN=

INNGEST_EVENT_KEY=

INNGEST_SIGNING_KEY=

RESEND_API_KEY=

UPSTASH_REDIS_REST_URL=

UPSTASH_REDIS_REST_TOKEN=
```

A complete `.env.example` significantly reduces onboarding time for new contributors.

---

# eslint.config.mjs

Linting enforces consistent coding standards across the project.

```javascript
import next from "eslint-config-next";

export default [

  ...next()

];
```

Additional project-specific rules can be introduced as the codebase evolves.

---

# postcss.config.mjs

```javascript
export default {

  plugins: {

    "@tailwindcss/postcss": {}

  }

};
```

---

# tailwind.config.ts

```ts
import type { Config } from "tailwindcss";

export default {

  content: [

    "./src/**/*.{ts,tsx}"

  ],

  theme: {

    extend: {}

  },

  plugins: []

} satisfies Config;
```

---

# components.json

Configuration for shadcn/ui.

```json
{
  "style": "default",

  "tsx": true,

  "tailwind": {

    "config": "tailwind.config.ts",

    "css": "src/app/globals.css"

  },

  "aliases": {

    "components": "@/components",

    "utils": "@/utils"

  }
}
```

---

# .gitignore

Typical entries include:

```text
node_modules/

.next/

.env

.env.local

coverage/

playwright-report/

dist/

*.log
```

Generated files should never be committed.

---

# README.md

The repository README should answer four questions immediately:

1. What is this project?
2. How do I run it?
3. Which technologies does it use?
4. Where should I start reading?

A concise README dramatically improves developer onboarding.

---

# Bootstrap Checklist

Before implementing application features, verify that:

* Dependencies install successfully.
* TypeScript compiles without errors.
* ESLint passes.
* Tailwind CSS renders correctly.
* Clerk authentication is configured.
* Sanity credentials are available.
* Inngest development server is running.
* Environment variables are loaded.
* The application starts without warnings.

Completing this checklist ensures a stable development environment.

---

# Looking Ahead

With the project scaffold complete, we can begin building the shared infrastructure that supports the entire application.

The next appendix introduces the `lib/` directory, including configuration management, logging, authentication helpers, Redis integration, Sanity client initialization, Inngest setup, and reusable utilities that form the backbone of the platform.
