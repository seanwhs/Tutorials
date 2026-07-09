# Part 4 Code Appendix — Full Snippets

Companion code for **EntNext16 - Part 4: Resilient Infrastructure and Deployment**.

---

## Nested Error Boundaries

### `app/error.tsx` (root catch-all)

```tsx
"use client";

import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("Unhandled app error:", error.digest, error);
  }, [error]);

  return (
    <div className="p-8 text-center">
      <h2 className="text-lg font-semibold">Something went wrong.</h2>
      <p className="text-sm text-gray-500">Reference: {error.digest ?? "n/a"}</p>
      <button onClick={reset} className="mt-4 underline">
        Try again
      </button>
    </div>
  );
}
```

### `app/dashboard/projects/[id]/error.tsx` (segment-scoped)

```tsx
"use client";

export default function ProjectDetailError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="rounded border border-red-200 bg-red-50 p-4">
      <p>Couldn't load this project. (Ref: {error.digest ?? "n/a"})</p>
      <button onClick={reset} className="underline text-sm">
        Retry
      </button>
    </div>
  );
}
```

This nested boundary catches errors thrown by `ProjectDetailPage` and its children without unmounting the parent `app/dashboard/layout.tsx` (nav/sidebar stay intact).

### `components/ui/error-boundary.tsx` (manual, widget-level)

```tsx
"use client";

import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback: ReactNode;
}

interface State {
  hasError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("Widget error boundary caught:", error, info.componentStack);
  }

  render() {
    if (this.state.hasError) return this.props.fallback;
    return this.props.children;
  }
}
```

### Usage — isolating a non-critical widget

```tsx
import { ErrorBoundary } from "@/components/ui/error-boundary";
import { RelatedItemsWidget } from "@/components/related-items-widget";

export function ProjectSidebar({ projectId }: { projectId: string }) {
  return (
    <aside>
      <ErrorBoundary fallback={<p className="text-xs text-gray-400">Related items unavailable.</p>}>
        <RelatedItemsWidget projectId={projectId} />
      </ErrorBoundary>
    </aside>
  );
}
```

---

## Granular Loading UI (Suspense per-section, not per-route)

```tsx
// app/dashboard/projects/[id]/page.tsx
import { Suspense } from "react";
import { ProjectStats } from "@/components/project-stats";
import { ProjectActivityLog } from "@/components/project-activity-log";
import { StatsSkeleton, ActivitySkeleton } from "@/components/ui/skeletons";

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  return (
    <div className="grid grid-cols-2 gap-6">
      {/* Fast section — resolves quickly, streams in first */}
      <Suspense fallback={<StatsSkeleton />}>
        <ProjectStats projectId={id} />
      </Suspense>

      {/* Slow section — streams independently, doesn't block Stats */}
      <Suspense fallback={<ActivitySkeleton />}>
        <ProjectActivityLog projectId={id} />
      </Suspense>
    </div>
  );
}
```

```tsx
// components/ui/skeletons.tsx
export function StatsSkeleton() {
  return <div className="h-24 animate-pulse rounded bg-gray-100" />;
}

export function ActivitySkeleton() {
  return <div className="h-64 animate-pulse rounded bg-gray-100" />;
}
```

---

## Facade Pattern for external SDKs

### `lib/facades/types.ts`

```ts
export type FacadeResult<T> =
  | { success: true; data: T }
  | { success: false; error: string };
```

### `lib/facades/payments.ts`

```ts
import "server-only";
import Stripe from "stripe";
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

export interface PaymentsFacade {
  createCharge(input: ChargeInput): Promise<FacadeResult<Charge>>;
}

class StripePaymentsFacade implements PaymentsFacade {
  private getClient(): Stripe {
    // Lazy-init inside the method, not at module scope — cheaper cold starts.
    return new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: "2024-06-20",
    });
  }

  async createCharge(input: ChargeInput): Promise<FacadeResult<Charge>> {
    const stripe = this.getClient();

    try {
      const timeoutMs = 8000;
      const result = await Promise.race([
        stripe.charges.create({
          amount: input.amountCents,
          currency: input.currency,
          customer: input.customerId,
        }),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error("Payments provider timed out")), timeoutMs)
        ),
      ]);

      return {
        success: true,
        data: { id: result.id, status: result.status as Charge["status"] },
      };
    } catch (err) {
      // Normalize any SDK-specific error shape into our own type.
      const message = err instanceof Error ? err.message : "Unknown payments error";
      return { success: false, error: message };
    }
  }
}

export const paymentsFacade: PaymentsFacade = new StripePaymentsFacade();
```

### Usage — application code never imports `stripe` directly

```ts
// lib/actions/billing-actions.ts
"use server";

import { paymentsFacade } from "@/lib/facades/payments";
import type { ActionResult } from "./types";
import type { Charge } from "@/lib/facades/payments";

export async function chargeCustomer(
  customerId: string,
  amountCents: number
): Promise<ActionResult<Charge>> {
  const result = await paymentsFacade.createCharge({
    amountCents,
    currency: "usd",
    customerId,
  });

  if (!result.success) {
    return { success: false, error: result.error };
  }

  return { success: true, data: result.data };
}
```

If you swap Stripe for another provider later, only `lib/facades/payments.ts` changes — every call site (`billing-actions.ts` and beyond) is untouched because it depends on `PaymentsFacade`, not the SDK.

---

## Anti-pattern reference (for contrast, do not copy)

```tsx
// BAD — direct SDK import scattered across the app, one page = one giant loading.tsx,
// no error isolation
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export default async function CheckoutPage() {
  const charge = await stripe.charges.create({ amount: 1000, currency: "usd" });
  // If this throws, the WHOLE page crashes — no boundary, no fallback.
  return <p>Charged: {charge.id}</p>;
}
```

---

That's the entire series, front to back — all 4 parts plus all 3 code appendices. 🎉

Want me to generate a **Part 5: Testing Strategy** (unit-testing repositories/facades, mocking Server Actions, integration-testing Suspense/error boundaries) to round out the series, or something else?
