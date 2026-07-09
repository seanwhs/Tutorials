# Part 6 Code Appendix — Full Snippets

Companion code for **Part 6: Observability and Structured Logging**.

---

## `lib/observability/types.ts`

```ts
export type LogLevel = "debug" | "info" | "warn" | "error";

export type LogContext = Record<string, string | number | boolean | null>;

export interface Logger {
  debug(message: string, context?: LogContext): void;
  info(message: string, context?: LogContext): void;
  warn(message: string, context?: LogContext): void;
  error(message: string, context?: LogContext): void;
}
```

## `lib/observability/logger.ts`

```ts
import "server-only";
import type { Logger, LogContext, LogLevel } from "./types";
import { getRequestId } from "./request-context";

class JsonLogger implements Logger {
  private write(level: LogLevel, message: string, context?: LogContext) {
    const entry = {
      level,
      message,
      context: context ?? {},
      requestId: getRequestId(),
      timestamp: new Date().toISOString(),
    };

    // Vercel's log drains capture stdout/stderr as structured JSON automatically.
    if (level === "error") {
      console.error(JSON.stringify(entry));
    } else {
      console.log(JSON.stringify(entry));
    }
  }

  debug(message: string, context?: LogContext) {
    this.write("debug", message, context);
  }

  info(message: string, context?: LogContext) {
    this.write("info", message, context);
  }

  warn(message: string, context?: LogContext) {
    this.write("warn", message, context);
  }

  error(message: string, context?: LogContext) {
    this.write("error", message, context);
  }
}

export const logger: Logger = new JsonLogger();
```

---

## `lib/observability/request-context.ts` (correlation ID via `cache()`)

```ts
import "server-only";
import { cache } from "react";
import { headers } from "next/headers";
import { randomUUID } from "crypto";

// Memoized per-request: called many times across repositories/actions/components
// during one request, but only computes once thanks to React's cache().
export const getRequestId = cache((): string => {
  return randomUUID();
});

// Optional: prefer an upstream-provided id (e.g., Vercel's x-vercel-id) if present,
// falling back to a freshly generated one.
export const getOrCreateRequestId = cache(async (): Promise<string> => {
  const headerList = await headers();
  const upstreamId = headerList.get("x-vercel-id");
  return upstreamId ?? randomUUID();
});
```

---

## `lib/observability/with-logging.ts` (higher-order wrapper for Server Actions)

```ts
import "server-only";
import { logger } from "./logger";

interface ResultLike {
  success: boolean;
}

export function withLogging<TArgs extends unknown[], TResult extends ResultLike>(
  actionName: string,
  fn: (...args: TArgs) => Promise<TResult>
) {
  return async (...args: TArgs): Promise<TResult> => {
    const start = Date.now();
    logger.info(`${actionName}.start`, { actionName });

    try {
      const result = await fn(...args);
      const durationMs = Date.now() - start;

      if (result.success) {
        logger.info(`${actionName}.success`, { actionName, durationMs });
      } else {
        logger.warn(`${actionName}.failure`, { actionName, durationMs });
      }

      return result;
    } catch (err) {
      const durationMs = Date.now() - start;
      const message = err instanceof Error ? err.message : "Unknown error";
      logger.error(`${actionName}.threw`, { actionName, durationMs, message });
      throw err;
    }
  };
}
```

---

## Usage — wrapping a Part 2 Server Action

```ts
// lib/actions/project-actions.ts
"use server";

import { z } from "zod";
import { revalidateTag } from "next/cache";
import { db } from "@/lib/db";
import { withLogging } from "@/lib/observability/with-logging";
import type { ActionResult } from "./types";
import type { Project } from "@/lib/repositories/types";

const archiveProjectSchema = z.object({
  id: z.string().uuid(),
});

async function archiveProjectImpl(id: string): Promise<ActionResult<Project>> {
  const parsed = archiveProjectSchema.safeParse({ id });
  if (!parsed.success) {
    return { success: false, error: "Invalid project id." };
  }

  try {
    const updated = await db.project.update({
      where: { id: parsed.data.id },
      data: { status: "archived" },
    });

    revalidateTag("projects");
    revalidateTag(`project:${parsed.data.id}`);

    return { success: true, data: updated };
  } catch {
    return { success: false, error: "Failed to archive project." };
  }
}

// Fully typed: callers still see (id: string) => Promise<ActionResult<Project>>.
export const archiveProject = withLogging("archiveProject", archiveProjectImpl);
```

---

## Usage — logging inside a repository (Part 1)

```ts
// lib/repositories/project-repository.ts
import "server-only";
import { logger } from "@/lib/observability/logger";
import type { Project, ProjectRepository } from "./types";

const API_BASE = process.env.API_BASE_URL!;

class HttpProjectRepository implements ProjectRepository {
  async getById(id: string): Promise<Project | null> {
    const res = await fetch(`${API_BASE}/projects/${id}`, {
      next: { tags: ["projects", `project:${id}`] },
    });

    if (res.status === 404) {
      logger.debug("project.notFound", { projectId: id });
      return null;
    }

    if (!res.ok) {
      logger.error("project.fetchFailed", { projectId: id, status: res.status });
      throw new Error(`Failed to load project ${id}: ${res.status}`);
    }

    return res.json();
  }

  async getAll(): Promise<Project[]> {
    const res = await fetch(`${API_BASE}/projects`, {
      next: { revalidate: 60, tags: ["projects"] },
    });

    if (!res.ok) {
      logger.error("project.listFetchFailed", { status: res.status });
      throw new Error(`Failed to load projects: ${res.status}`);
    }

    return res.json();
  }
}

export const projectRepository: ProjectRepository = new HttpProjectRepository();
```

---

## Usage — logging inside a Facade (Part 4) before normalizing the error

```ts
// lib/facades/payments.ts
import "server-only";
import Stripe from "stripe";
import { logger } from "@/lib/observability/logger";
import type { FacadeResult } from "./types";

export interface ChargeInput {
  amountCents: number;
  currency: string;
  customerId: string;
}

export interface Charge {
  id: string;
  status: "succeeded" | "pending" | "failed";
}

class StripePaymentsFacade {
  private getClient(): Stripe {
    return new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2024-06-20" });
  }

  async createCharge(input: ChargeInput): Promise<FacadeResult<Charge>> {
    const stripe = this.getClient();
    logger.info("payments.createCharge.start", {
      currency: input.currency,
      amountCents: input.amountCents,
    });

    try {
      const result = await stripe.charges.create({
        amount: input.amountCents,
        currency: input.currency,
        customer: input.customerId,
      });

      logger.info("payments.createCharge.success", { chargeId: result.id });
      return { success: true, data: { id: result.id, status: result.status as Charge["status"] } };
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unknown payments error";
      logger.error("payments.createCharge.failed", { message });
      return { success: false, error: message };
    }
  }
}

export const paymentsFacade = new StripePaymentsFacade();
```

---

## Surfacing the correlation ID in the user-facing error UI (Part 4 tie-in)

```tsx
// app/dashboard/projects/[id]/error.tsx
"use client";

import { useEffect } from "react";
import { logger } from "@/lib/observability/logger";

export default function ProjectDetailError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Client-side logger call — in a real app this posts to a client-safe
    // logging endpoint rather than writing server JSON directly from the browser.
    console.error("Project detail error boundary triggered", {
      digest: error.digest,
    });
  }, [error]);

  return (
    <div className="rounded border border-red-200 bg-red-50 p-4">
      <p>Couldn't load this project.</p>
      <p className="text-xs text-gray-500">
        Reference: {error.digest ?? "n/a"} — include this if you contact support.
      </p>
      <button onClick={reset} className="underline text-sm">
        Retry
      </button>
    </div>
  );
}
```

`error.digest` is Next.js's own correlation identifier for errors thrown during rendering — pairing it with your own `requestId` (logged server-side via `getRequestId()`) is what lets a support engineer paste a user's "Reference: ..." string into your log aggregator and land directly on the relevant structured log lines.

---

## Anti-pattern reference (for contrast, do not copy)

```ts
// BAD — unstructured, unqueryable, no correlation to the request that failed
export async function archiveProject(id: string) {
  console.log("archiving", id);
  try {
    const updated = await db.project.update({ where: { id }, data: { status: "archived" } });
    console.log("done", updated);
    return updated;
  } catch (err) {
    console.log("error!!", err);
    throw err;
  }
}
```
