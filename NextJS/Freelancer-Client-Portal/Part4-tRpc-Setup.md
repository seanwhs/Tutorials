# Part 4: tRPC Setup

Previous: Part 3 (Database).

Targets tRPC 11.x. tRPC's plumbing isn't Next.js-version-specific — but `createTRPCContext` calls Clerk's async `auth()`, and every dynamic page calling `getServerApi()` must itself be an `async` Server Component to await through correctly.

## 1. Concept

tRPC lets us write backend "procedures" grouped into "routers", called from React with full TypeScript autocomplete — no manual fetch/JSON/schema work. We set up:
- A **context** — Prisma `db` + current Clerk user, on every request.
- **trpc.ts** — `publicProcedure`, `protectedProcedure` (signed-in), `adminProcedure` (ADMIN only).
- A **root router** expanded in later parts.
- An **API route handler** exposing tRPC over HTTP.
- **Client wiring** for Server/Client Components.

## 2. Install packages

```bash
pnpm add @trpc/server @trpc/client @trpc/react-query @trpc/next @tanstack/react-query zod superjson
```

## 3. Context

```ts
// src/server/api/trpc.ts
import { initTRPC, TRPCError } from "@trpc/server";
import superjson from "superjson";
import { auth } from "@clerk/nextjs/server";
import { db } from "@/server/db";

export const createTRPCContext = async () => {
  const { userId, sessionClaims } = await auth();
  const role = (sessionClaims?.metadata as { role?: string } | undefined)?.role;

  return {
    db,
    clerkUserId: userId,
    role,
  };
};

type Context = Awaited<ReturnType<typeof createTRPCContext>>;

const t = initTRPC.context<Context>().create({
  transformer: superjson,
  errorFormatter({ shape }) {
    return shape;
  },
});

export const createTRPCRouter = t.router;
export const publicProcedure = t.procedure;

/** Requires a signed-in Clerk user. Loads (or lazily creates) our internal User row. */
export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.clerkUserId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }

  const user = await ctx.db.user.findUnique({
    where: { clerkId: ctx.clerkUserId },
  });

  if (!user) {
    throw new TRPCError({ code: "UNAUTHORIZED", message: "User not synced yet." });
  }

  return next({
    ctx: {
      ...ctx,
      user,
    },
  });
});

/** Requires the internal User row to have role ADMIN. */
export const adminProcedure = protectedProcedure.use(async ({ ctx, next }) => {
  if (ctx.user.role !== "ADMIN") {
    throw new TRPCError({ code: "FORBIDDEN" });
  }
  return next({ ctx });
});
```

`protectedProcedure` looks up our own `User` row — created via Part 5's Clerk webhook. Until then, protected procedures will fail; expected.

## 4. Root router (empty for now)

```ts
// src/server/api/root.ts
import { createTRPCRouter } from "@/server/api/trpc";

export const appRouter = createTRPCRouter({
  // routers get added here in later parts
});

export type AppRouter = typeof appRouter;
```

## 5. API route handler

```ts
// src/app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { appRouter } from "@/server/api/root";
import { createTRPCContext } from "@/server/api/trpc";

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: "/api/trpc",
    req,
    router: appRouter,
    createContext: createTRPCContext,
    onError:
      process.env.NODE_ENV === "development"
        ? ({ path, error }) => {
            console.error(`❌ tRPC failed on ${path ?? "<no-path>"}: ${error.message}`);
          }
        : undefined,
  });

export { handler as GET, handler as POST };
```

The `[trpc]` folder is a catch-all dynamic route segment — unrelated to the `params` Promise pattern, since `fetchRequestHandler` parses the path itself.

## 6. Client-side wiring

```tsx
// src/trpc/client.tsx
"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { httpBatchLink, loggerLink } from "@trpc/client";
import { createTRPCReact } from "@trpc/react-query";
import { useState } from "react";
import superjson from "superjson";
import type { AppRouter } from "@/server/api/root";

export const api = createTRPCReact<AppRouter>();

function getBaseUrl() {
  if (typeof window !== "undefined") return "";
  if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`;
  return `http://localhost:${process.env.PORT ?? 3000}`;
}

export function TRPCReactProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());

  const [trpcClient] = useState(() =>
    api.createClient({
      links: [
        loggerLink({
          enabled: (op) =>
            process.env.NODE_ENV === "development" ||
            (op.direction === "down" && op.result instanceof Error),
        }),
        httpBatchLink({
          url: `${getBaseUrl()}/api/trpc`,
          transformer: superjson,
        }),
      ],
    })
  );

  return (
    <api.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </api.Provider>
  );
}
```

Wrap the app (updates `src/app/layout.tsx` to nest `TRPCReactProvider` inside `ClerkProvider`).

## 7. Server-side caller (for React Server Components)

```ts
// src/trpc/server.ts
import "server-only";
import { createTRPCContext } from "@/server/api/trpc";
import { appRouter } from "@/server/api/root";

export async function getServerApi() {
  const ctx = await createTRPCContext();
  return appRouter.createCaller(ctx);
}
```

Usage:

```tsx
export default async function SomePage() {
  const api = await getServerApi();
  const clients = await api.client.list();
}
```

## 8. Sanity-check router

```ts
// src/server/api/routers/health.ts
import { createTRPCRouter, publicProcedure } from "@/server/api/trpc";

export const healthRouter = createTRPCRouter({
  ping: publicProcedure.query(() => {
    return { message: "pong", time: new Date().toISOString() };
  }),
});
```

Register it in `root.ts`, then test via a temporary client component:

```tsx
"use client";
import { api } from "@/trpc/client";

function HealthCheck() {
  const { data } = api.health.ping.useQuery();
  return <p>{data ? `${data.message} @ ${data.time}` : "loading..."}</p>;
}
```

(Remove before Part 5.)

## Checkpoint

- [ ] `pnpm dev` compiles cleanly
- [ ] `<HealthCheck />` shows `pong @ <timestamp>`
- [ ] `AppRouter` type autocompletes as `api.`

## Troubleshooting

- **Cannot find module 'server-only'**: `pnpm add server-only`
- **404 on /api/trpc/...**: confirm folder literally `[trpc]`
- **ctx.user undefined**: expected until Part 5's webhook exists

## Next

Continue to **Part 5: Clients & Projects**.
