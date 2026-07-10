# Part 6: API Evolution

## 1. The API Is a Contract, and Contracts Are Expensive to Break

Once an API has external consumers — a mobile app, a partner integration, even your own frontend deployed independently of the backend — every field, every endpoint shape, every status code becomes a **promise**. Breaking that promise doesn't just cost you a refactor; it costs *every consumer* a coordinated fix, often on a timeline you don't control. This is why API design deserves the same Cost-of-Change discipline as domain modeling, just aimed outward instead of inward.

## 2. RESTful vs. RPC-Style: Choosing Deliberately

| Style | Shape | Best for | Trade-off |
|---|---|---|---|
| **REST** | Resource-oriented (`/orders/:id`, verbs via HTTP methods) | Public APIs, CRUD-heavy resources, cacheable reads | Awkward for actions that aren't naturally CRUD ("cancel order" isn't a clean PUT) |
| **RPC-style** (e.g., `/api/orders.place`, tRPC, Server Actions) | Action-oriented, named procedures | Internal APIs, action-heavy workflows, strongly-typed monorepos | Less cacheable by default, less "discoverable" to generic HTTP tooling |

**Architectural guidance:** don't dogmatically pick one. Northwind Orders uses **REST for public-facing resource reads** (`GET /api/v1/products`, cacheable, CDN-friendly) and **RPC-style Server Actions/tRPC for internal action-oriented writes** (`placeOrder`, `cancelOrder` — these are verbs, not resources, and forcing them into REST's CRUD mold often produces awkward, ambiguous endpoints like `PATCH /orders/:id { status: "cancelled" }` that hide intent behind a generic update).

```ts
// app/api/v1/products/route.ts — REST, public, cacheable
import { NextRequest, NextResponse } from "next/server";
import { catalogReader } from "@/infrastructure/container";

export async function GET(req: NextRequest) {
  const products = await catalogReader.listAll();
  return NextResponse.json(
    { data: products.map(toProductDTO) },
    { headers: { "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300" } }
  );
}

function toProductDTO(p: { sku: string; name: string; priceCents: number }) {
  // Never leak the domain entity directly — always map to a DTO.
  // This is the seam that lets the domain model change shape freely
  // without breaking the public contract.
  return { sku: p.sku, name: p.name, price: p.priceCents / 100 };
}
```

```ts
// app/actions/cancel-order.ts — RPC-style, internal, action-oriented
"use server";
import { cancelOrderUseCase } from "@/infrastructure/container";

export async function cancelOrderAction(orderId: string) {
  const result = await cancelOrderUseCase.execute(orderId);
  return result;
}
```

## 3. The DTO Boundary: Never Leak the Domain Model

Notice `toProductDTO` above. This is not boilerplate for its own sake — it is the single most important habit for API longevity. If an API handler returns a domain entity directly (`return NextResponse.json(order)`), then **every internal field of `Order` becomes part of the public contract**, whether you intended it or not. Add a private field to the domain model next month, and you've silently changed the API. The DTO mapping function is a deliberate, versionable seam.

```ts
// interface-adapters/dtos/OrderDTO.ts
import { Order } from "@/core/ordering/domain/entities/Order";

export interface OrderDTOv1 {
  id: string;
  status: string;
  totalDollars: number;
  lineItems: { sku: string; quantity: number }[];
}

export function toOrderDTOv1(order: Order): OrderDTOv1 {
  return {
    id: order.id,
    status: order.status,
    totalDollars: order.total().toDollars(),
    lineItems: order.lineItems.map((li) => ({ sku: li.sku, quantity: li.quantity })),
  };
}
```

## 4. Schema Versioning Strategies

| Strategy | Example | Trade-off |
|---|---|---|
| **URI versioning** | `/api/v1/orders`, `/api/v2/orders` | Explicit, simple, but can lead to duplicated route logic |
| **Header versioning** | `Accept: application/vnd.northwind.v2+json` | Cleaner URLs, less discoverable, harder to test manually |
| **Additive-only (no version bump)** | Always add optional fields, never remove/rename | Lowest ceremony, works until a truly breaking change is unavoidable |

**Architectural default:** prefer **additive-only evolution** for as long as possible (mirrors the expand/contract schema pattern from Part 4 — same philosophy, applied to the API layer). Only introduce a new URI version (`v2`) when a change is *fundamentally* incompatible (e.g., changing `totalDollars: number` to `total: Money` object shape) — and even then, keep `v1` alive and simply mapped from the same underlying domain model, so you maintain one domain, N contract adapters.

```ts
// app/api/v2/orders/[id]/route.ts
import { toOrderDTOv2 } from "@/interface-adapters/dtos/OrderDTOv2";

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const order = await orderRepository.findById(params.id);
  if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });
  return NextResponse.json(toOrderDTOv2(order)); // v1 route still exists, uses toOrderDTOv1
}
```

Both v1 and v2 routes call the *same* `orderRepository` and operate on the *same* `Order` domain entity — versioning lives entirely at the DTO/adapter layer, never forking the domain. This is the Dependency Rule from Part 1, applied to API versioning: the domain must never fork just to satisfy a contract concern.

## 5. Building a Lightweight API Gateway/Orchestration Layer

As the system grows (more contexts, more consumers), a thin **Backend-for-Frontend (BFF)** or gateway layer becomes valuable: one place that composes calls to multiple internal use cases, applies cross-cutting concerns (auth, rate limiting, logging), and presents a single coherent contract to a given client type — all without those concerns leaking into `core/`.

```ts
// interface-adapters/gateway/withApiMiddleware.ts
import { NextRequest, NextResponse } from "next/server";

type Handler = (req: NextRequest) => Promise<NextResponse>;

export function withApiMiddleware(handler: Handler): Handler {
  return async (req: NextRequest) => {
    const start = Date.now();

    // Cross-cutting concern #1: auth (stubbed — free/OSS: verify a JWT locally, no paid auth SaaS required)
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Cross-cutting concern #2: basic rate limiting (in-memory token bucket — zero external service)
    // ... omitted for brevity, see Appendix A for free rate-limiting approaches

    try {
      const response = await handler(req);
      console.log(`[api] ${req.method} ${req.url} — ${Date.now() - start}ms`);
      return response;
    } catch (err) {
      console.error(`[api] error handling ${req.url}`, err);
      return NextResponse.json({ error: "Internal error" }, { status: 500 });
    }
  };
}
```

```ts
// app/api/v1/orders/[id]/route.ts
import { withApiMiddleware } from "@/interface-adapters/gateway/withApiMiddleware";
import { orderRepository } from "@/infrastructure/container";
import { toOrderDTOv1 } from "@/interface-adapters/dtos/OrderDTO";

export const GET = withApiMiddleware(async (req) => {
  const id = req.nextUrl.pathname.split("/").pop()!;
  const order = await orderRepository.findById(id);
  if (!order) return Response.json({ error: "Not found" }, { status: 404 });
  return Response.json(toOrderDTOv1(order));
});
```

This composable-middleware pattern is deliberately simple (a higher-order function, not a heavyweight gateway product) — it's a good example of "pay for complexity only when you need it." If Northwind Orders later needs a dedicated API gateway service (e.g., Kong, or a custom Node service) fronting multiple backend deployables, this middleware pattern is exactly what gets *extracted* into that gateway, unchanged in spirit.

## 6. Design Exercise

**Step 1:** Design the public API surface for Notifications preferences (`GET/PUT /api/v1/customers/:id/notification-preferences`). Write the DTO — what fields belong in the public contract vs. what stays purely internal (e.g., an internal `deliveryProviderId` should never appear)?

**Step 2:** A breaking change is requested: split a single `phone` field into `phoneCountryCode` and `phoneNumber`. Design an additive-only migration path that avoids a `v2` bump.

**Step 3:** Identify one workflow in Northwind Orders that is a poor fit for REST and would be clearer as an RPC-style action. Justify with the "is this a resource or a verb" test.

## 7. Solution & Discussion

**Step 1:** Public DTO: `{ customerId, emailEnabled, smsEnabled, pushEnabled }`. Internal-only, never exposed: which third-party provider handles delivery, retry counts, internal provider message IDs — these are infrastructure details from Part 3's `NotificationSender` adapter and have no business being in a public contract.

**Step 2:** Additive-only path: add `phoneCountryCode` and `phoneNumber` as new *optional* fields alongside the existing `phone` field. Populate both on writes. Deprecate `phone` in documentation immediately, but don't remove it from the response until telemetry confirms zero consumers still read it (mirrors the expand/contract pattern from Part 4, applied to an API contract instead of a database column).

**Step 3:** "Cancel order" is the classic example — it's an action/verb, not a resource creation or replacement. Modeling it as `PATCH /orders/:id { status: "cancelled" }` hides the actual business operation (which enforces "can only cancel if not yet shipped," per the `Order` entity's rules from Part 2) behind a generic field update, inviting consumers to attempt invalid transitions that a well-named RPC action (`cancelOrderAction`) can validate explicitly and reject with a clear domain-level reason.

## Up Next

**Part 7 (Architectural Decision Records)** captures the *reasoning* behind choices like "REST for public reads, RPC for internal actions" or "additive-only versioning by default" — so future maintainers (including future-you) never have to reverse-engineer *why* the system looks the way it does.

