# Part 5: Resilience & Scalability

## 1. Designing for Failure Is Designing for Reality

Every external dependency in Northwind Orders — the Payment Gateway, the Notification provider, even the database under high load — **will** fail eventually. The architectural question isn't "how do we prevent failure" (impossible), it's "how do we make failure cheap, contained, and recoverable." This is the Cost of Change lens applied to *runtime* behavior rather than code structure: an unresilient system's "cost of a bad day" is an outage; a resilient system's cost is a logged warning and a slightly slower response.

## 2. Retries with Exponential Backoff

A naive retry loop hammers a struggling dependency harder, making things worse (retry storms). Exponential backoff with jitter spaces out retries so a recovering service isn't immediately re-overwhelmed.

```ts
// core/shared-kernel/resilience/retry.ts
// Pure, framework-agnostic — lives in core because "retry a fallible operation"
// is a reusable policy, not an infrastructure detail.

export interface RetryOptions {
  maxAttempts: number;
  baseDelayMs: number;
  maxDelayMs: number;
}

export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  options: RetryOptions = { maxAttempts: 3, baseDelayMs: 200, maxDelayMs: 5000 }
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= options.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (attempt === options.maxAttempts) break;

      const exponential = options.baseDelayMs * 2 ** (attempt - 1);
      const jitter = Math.random() * exponential * 0.3;
      const delay = Math.min(exponential + jitter, options.maxDelayMs);

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}
```

**Why this lives in `core/shared-kernel`, not infrastructure:** retry policy is a *domain-agnostic algorithm*, not tied to any specific external system. It's used *by* infrastructure adapters, but it doesn't know or care whether it's retrying an HTTP call or a database write. Keeping it framework/infrastructure-agnostic means it's trivially unit-testable and reusable everywhere.

## 3. Circuit Breakers: Stop Calling What's Already Broken

Retries help with transient blips. But if a dependency is *fully down* for an extended period, retrying every request just wastes time and resources on both sides, and can cascade the failure to your own system (thread/connection pool exhaustion). A **Circuit Breaker** tracks failure rate and "opens" (fails fast, no network call at all) once a threshold is crossed, then periodically allows a trial request through ("half-open") to check for recovery.

```ts
// core/shared-kernel/resilience/CircuitBreaker.ts

type CircuitState = "closed" | "open" | "half-open";

export class CircuitBreaker {
  private state: CircuitState = "closed";
  private failureCount = 0;
  private lastFailureTime = 0;

  constructor(
    private readonly failureThreshold = 5,
    private readonly openDurationMs = 30_000
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === "open") {
      if (Date.now() - this.lastFailureTime > this.openDurationMs) {
        this.state = "half-open";
      } else {
        throw new Error("Circuit is open — failing fast without calling dependency");
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (err) {
      this.onFailure();
      throw err;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = "closed";
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = "open";
    }
  }
}
```

**Composing retry + circuit breaker in an adapter:**

```ts
// infrastructure/payments/ResilientPaymentGateway.ts
import { PaymentGateway } from "@/core/ordering/application/ports/PaymentGateway";
import { retryWithBackoff } from "@/core/shared-kernel/resilience/retry";
import { CircuitBreaker } from "@/core/shared-kernel/resilience/CircuitBreaker";

export class ResilientPaymentGateway implements PaymentGateway {
  private readonly breaker = new CircuitBreaker(5, 30_000);

  constructor(private readonly inner: PaymentGateway) {}

  async charge(orderId: string, amountCents: number) {
    return this.breaker.execute(() =>
      retryWithBackoff(() => this.inner.charge(orderId, amountCents), {
        maxAttempts: 3,
        baseDelayMs: 200,
        maxDelayMs: 2000,
      })
    );
  }
}
```

This is the **Decorator pattern** applied to a Port: `ResilientPaymentGateway` wraps any `PaymentGateway` implementation, adding resilience without either the real gateway or the `PlaceOrderUseCase` knowing anything changed. The composition root simply wires `new ResilientPaymentGateway(new RealStripeGateway())` instead of the bare gateway — zero changes anywhere else in the system.

## 4. Caching Strategies

| Strategy | Description | Trade-off |
|---|---|---|
| **Cache-aside** | App checks cache first; on miss, reads from source and populates cache | Simple; risk of stale reads until TTL expires |
| **Write-through** | Every write updates cache and source together | Cache always fresh; adds write latency |
| **Stale-while-revalidate** | Serve stale cached data immediately, refresh in background | Best perceived performance; requires tolerance for slight staleness |

```ts
// infrastructure/catalog/CachedCatalogReader.ts
// Decorator again — same pattern as the resilient payment gateway.
import { CatalogReader } from "@/core/catalog/application/ports/CatalogReader";
import { Product } from "@/core/catalog/domain/entities/Product";

interface CacheEntry {
  value: Product;
  expiresAt: number;
}

export class CachedCatalogReader implements CatalogReader {
  private cache = new Map<string, CacheEntry>();

  constructor(
    private readonly inner: CatalogReader,
    private readonly ttlMs = 60_000
  ) {}

  async findBySku(sku: string): Promise<Product | null> {
    const cached = this.cache.get(sku);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.value;
    }

    const fresh = await this.inner.findBySku(sku);
    if (fresh) {
      this.cache.set(sku, { value: fresh, expiresAt: Date.now() + this.ttlMs });
    }
    return fresh;
  }
}
```

**Next.js-native caching** complements this at the framework layer — `fetch` with `next: { revalidate: 60 }`, Route Handler segment caching, and React's `cache()` for request-level memoization. Use those for framework-level HTTP/render caching; use the decorator pattern above for domain-level caching that must survive a framework swap. Keeping both available and knowing which layer to reach for is itself an architectural skill — reaching for framework caching inside `core/` would violate the Dependency Rule from Part 1.

## 5. Graceful Degradation

When a dependency is unavailable, the system should degrade a *feature*, not crash the *page*. On Next.js's Edge runtime (fast cold starts, globally distributed, ideal for this kind of defensive logic), a pattern like this keeps checkout available even if a non-critical dependency (like a recommendation engine) is down:

```tsx
// app/checkout/RecommendedProducts.tsx (Server Component)
import { getRecommendations } from "@/infrastructure/recommendations/client";

export async function RecommendedProducts({ customerId }: { customerId: string }) {
  try {
    const recs = await getRecommendations(customerId);
    return <ProductGrid products={recs} />;
  } catch {
    // Degrade gracefully: no recommendations widget, but checkout still works.
    return null;
  }
}
```

The architectural rule this encodes: **non-critical dependencies must be isolated so their failure cannot block critical paths.** Placing this Server Component as an independent Suspense boundary (see the React 19 Mastery series, Module 2, for the `use` hook + Suspense streaming pattern) means even a *slow* recommendations call doesn't block order placement from rendering.

## 6. Design Exercise

**Step 1:** Identify which Northwind Orders dependencies are *critical path* (must succeed for the core flow to work) vs. *non-critical* (can degrade gracefully): Payment Gateway, Notification provider, Recommendation engine, Inventory check.

**Step 2:** For each critical-path dependency, decide: retry, circuit breaker, both, or neither? Justify using failure-mode reasoning (is the failure likely transient or sustained?).

**Step 3:** Design a caching strategy for the Catalog's product listing page. Which strategy (cache-aside, write-through, stale-while-revalidate) fits best, and why, given that product prices change infrequently but must never be *wrong* at checkout time?

## 7. Solution & Discussion

**Step 1:** Critical path: Payment Gateway (order cannot complete without it), Inventory check (must know stock exists). Non-critical: Notification provider (order can succeed even if the confirmation email is delayed — the outbox pattern from Part 4 already ensures it's *eventually* delivered), Recommendation engine (pure UX enhancement).

**Step 2:** Payment Gateway: both retry (handles transient network blips) and circuit breaker (protects against sustained outages, avoids hammering a payment provider that may rate-limit or ban clients showing abusive retry behavior). Inventory check: retry only, with a short timeout — an open circuit here should probably fail the order attempt with a clear "try again shortly" message rather than silently degrade, since overselling stock is a worse outcome than a delayed order.

**Step 3:** Stale-while-revalidate for the *listing/browse* page (users tolerate a few seconds of staleness browsing a catalog), but cache-aside with a very short TTL — or no cache at all — for the *final price shown at checkout confirmation*. This is a deliberate split: the same Product data gets different caching treatment depending on *where* in the flow it's read, because the cost of a stale read differs enormously between "browsing" and "about to charge a card." This nuance is exactly why caching decisions belong in infrastructure adapters (per-use-case decorators), not as a single blanket cache slapped on the repository.

## Up Next

**Part 6 (API Evolution)** shifts focus outward: now that the internal system is resilient, how do we expose it to clients (web, mobile, partners) via APIs that can evolve for years without breaking every consumer on every change?

