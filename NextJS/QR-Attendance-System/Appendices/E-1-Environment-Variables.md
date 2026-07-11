# Appendix E.1

## File: `src/lib/config/env.ts`

**Purpose**

Centralizes all environment variable access using **Zod**. The application validates its configuration once during startup and exports a fully typed configuration object for use throughout the codebase.

This approach prevents configuration errors from surfacing at runtime and eliminates scattered `process.env` access across the project.

```typescript
/**
 * ============================================================================
 * File: src/lib/config/env.ts
 * ----------------------------------------------------------------------------
 * Centralized environment configuration.
 *
 * Every environment variable used by the application is validated here.
 * No other module should access process.env directly.
 * ============================================================================
 */

import { z } from "zod";

/**
 * ---------------------------------------------------------------------------
 * Environment Schema
 * ---------------------------------------------------------------------------
 */

const envSchema = z.object({
  /**
   * Application
   */
  NODE_ENV: z.enum(["development", "test", "production"]),

  NEXT_PUBLIC_APP_URL: z.url(),

  /**
   * Clerk
   */
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().min(1),

  CLERK_SECRET_KEY: z.string().min(1),

  NEXT_PUBLIC_CLERK_SIGN_IN_URL: z.string().default("/sign-in"),

  NEXT_PUBLIC_CLERK_SIGN_UP_URL: z.string().default("/sign-up"),

  /**
   * Sanity
   */
  SANITY_PROJECT_ID: z.string().min(1),

  SANITY_DATASET: z.string().min(1),

  SANITY_API_VERSION: z.string().default("2025-01-01"),

  SANITY_API_TOKEN: z.string().min(1),

  /**
   * Inngest
   */
  INNGEST_EVENT_KEY: z.string().min(1),

  INNGEST_SIGNING_KEY: z.string().min(1),

  /**
   * Resend
   */
  RESEND_API_KEY: z.string().min(1),

  EMAIL_FROM: z.email(),

  /**
   * Upstash Redis
   */
  UPSTASH_REDIS_REST_URL: z.url(),

  UPSTASH_REDIS_REST_TOKEN: z.string().min(1),

  /**
   * Feature Flags
   */
  ENABLE_GEOLOCATION: z
    .string()
    .default("false")
    .transform(value => value === "true"),

  ENABLE_OFFLINE_MODE: z
    .string()
    .default("true")
    .transform(value => value === "true"),

  ENABLE_EMAIL_NOTIFICATIONS: z
    .string()
    .default("true")
    .transform(value => value === "true"),
});

/**
 * ---------------------------------------------------------------------------
 * Parse & Validate
 * ---------------------------------------------------------------------------
 */

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error(
    "\n❌ Invalid environment configuration\n"
  );

  console.error(parsed.error.format());

  throw new Error(
    "Application startup aborted due to invalid environment variables."
  );
}

/**
 * ---------------------------------------------------------------------------
 * Export Typed Configuration
 * ---------------------------------------------------------------------------
 */

export const env = parsed.data;

/**
 * ---------------------------------------------------------------------------
 * Useful Helpers
 * ---------------------------------------------------------------------------
 */

export const isDevelopment =
  env.NODE_ENV === "development";

export const isProduction =
  env.NODE_ENV === "production";

export const isTest =
  env.NODE_ENV === "test";

/**
 * ---------------------------------------------------------------------------
 * Application Constants
 * ---------------------------------------------------------------------------
 */

export const AppConfig = {
  appName: "Attendance Platform",

  appUrl: env.NEXT_PUBLIC_APP_URL,

  sanity: {
    projectId: env.SANITY_PROJECT_ID,

    dataset: env.SANITY_DATASET,

    apiVersion: env.SANITY_API_VERSION,
  },

  clerk: {
    publishableKey:
      env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  },

  features: {
    geolocation:
      env.ENABLE_GEOLOCATION,

    offlineMode:
      env.ENABLE_OFFLINE_MODE,

    emailNotifications:
      env.ENABLE_EMAIL_NOTIFICATIONS,
  },
} as const;

/**
 * ---------------------------------------------------------------------------
 * Export Types
 * ---------------------------------------------------------------------------
 */

export type Environment = typeof env;

export type AppConfiguration = typeof AppConfig;
```

---

## Design Notes

This file establishes several conventions that the rest of the codebase will follow:

* **Single source of truth:** No other file should read `process.env` directly. All configuration flows through the exported `env` object.
* **Fail fast:** Configuration errors are detected during application startup rather than during request handling.
* **Strong typing:** Consumers receive typed configuration values, including transformed booleans, reducing repetitive parsing logic.
* **Centralized feature flags:** Optional capabilities (such as geolocation or offline support) can be enabled or disabled without scattering conditionals throughout the application.

---

### Next File

The next file should be:

```
src/lib/sanity/client.ts
```

This will build on the validated configuration in `env.ts` and create the application's read and write Sanity clients, following current **Next.js 16**, **Sanity v4**, and **`next-sanity`** best practices. This is where the repository begins interacting with external services.
