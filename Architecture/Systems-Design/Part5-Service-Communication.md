## Part 5: Service Communication

### 1. Concept and Philosophy

As a system grows past a single monolithic app server, its pieces need to talk to each other. How they talk (sync/async) and how they find each other is a decision with real latency, coupling, and failure consequences. Staff Engineer's rule: prefer async communication (Part 4) by default; reserve sync calls for when the caller genuinely cannot proceed without the response. Every sync call is a piece of your own latency budget and availability outsourced to another team's service.

### 2. Synchronous Communication: REST vs gRPC

**REST/HTTP/JSON**: human-readable, cacheable, universally supported. JSON serialization is comparatively slow/verbose, no built-in strong contract.

**gRPC/HTTP2/Protobuf**: binary serialization (smaller, faster), strongly-typed `.proto` contracts generating client/server code, built-in streaming support. Cost: not human-readable on the wire, not natively browser-cacheable, steeper setup (codegen).

Decision framework: REST for public-facing APIs (cacheability, debuggability, broad compatibility). gRPC for internal service-to-service calls where performance matters and you want compile-time contract safety.

Example — Quikn's internal link-validation service (blocklist check):

```
// link_validator.proto
syntax = "proto3";

service LinkValidator {
  rpc ValidateUrl (ValidateUrlRequest) returns (ValidateUrlResponse);
}

message ValidateUrlRequest {
  string destination_url = 1;
  string requesting_user_id = 2;
}

message ValidateUrlResponse {
  bool is_allowed = 1;
  string reason = 2; // populated only if is_allowed is false
}
```

Why gRPC here but REST for public link creation: link creation is public-facing, needs simple integration (REST/OpenAPI), low internal call frequency. The blocklist check is called by multiple internal services at high frequency and benefits from a strongly-typed shared contract, never needing to be human-readable on the wire.

### 3. Asynchronous Patterns (cross-reference to Part 4)

Fire-and-forget suits side effects. **Request-async-reply** (immediate ack + tracking ID, poll or webhook later) suits long-running work like a bulk CSV import:

```
// app/api/links/bulk-import/route.ts
export async function POST(req: NextRequest) {
  const file = await req.formData();
  const jobId = crypto.randomUUID();

  await inngest.send({
    name: "links/bulk-import.requested",
    data: { jobId, fileUrl: await uploadToStorage(file) },
  });

  // Immediate response: caller polls GET /api/jobs/:jobId or receives a webhook later
  return NextResponse.json({ jobId, status: "processing" }, { status: 202 });
}
```

HTTP 202 Accepted is the explicit signal: "accepted, not done, here's how to check." REST APIs too often force everything into synchronous 200-or-error even when the work is fundamentally async.

### 4. Service Discovery

Instances come and go (autoscaling, deploys, crashes), so callers can't hardcode IPs.

- **DNS-based discovery**: service name resolves to a load-balanced set of IPs (or the LB itself, Part 2). Simplest, default in most containerized/cloud deployments.
- **Client-side discovery with a registry** (Consul, etcd, both free/OSS): services register/deregister themselves; clients query directly. More moving parts, but avoids an extra hop when internal latency budgets are extremely tight.

For this series' scale: DNS-based discovery through the L7 load balancer is the pragmatic default — no extra HA infrastructure needed until operating dozens of internal services with very tight SLOs.

### 5. API Gateway

Single entry point for external clients handling cross-cutting concerns: auth, rate limiting (Part 6), routing, response aggregation, centralized logging/metrics.

```
server {
    listen 443 ssl;
    server_name api.quikn.example.com;

    location /v1/links {
        auth_request /internal/verify-token;
        proxy_pass http://links_service;
    }

    location /v1/analytics {
        auth_request /internal/verify-token;
        proxy_pass http://analytics_service;
    }

    location = /internal/verify-token {
        internal;
        proxy_pass http://auth_service/verify;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
    }
}
```

Why centralize `auth_request`: one place to fix an auth bug instead of N places, keeps each backend service focused on its own domain logic.

Application-code equivalent (Next.js middleware as a lightweight gateway):

```
// middleware.ts
import { NextRequest, NextResponse } from "next/server";
import { verifyToken } from "@/lib/auth";

export async function middleware(req: NextRequest) {
  const token = req.headers.get("authorization");
  const claims = token ? await verifyToken(token) : null;

  if (!claims && req.nextUrl.pathname.startsWith("/v1/")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const res = NextResponse.next();
  res.headers.set("x-user-id", claims?.userId ?? "");
  return res;
}

export const config = { matcher: "/v1/:path*" };
```

### 6. C4 Diagram, Service Communication Overview

```
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

Person(client, "External Client / Browser")
Container(gateway, "API Gateway", "Nginx + middleware", "Auth, rate limiting, routing")
Container(linksSvc, "Links Service", "Next.js (REST)", "Public CRUD for links")
Container(analyticsSvc, "Analytics Service", "Next.js (REST)", "Public read-only analytics")
Container(validatorSvc, "Link Validator", "Internal gRPC service", "Blocklist checks, internal only")

Rel(client, gateway, "HTTPS / REST")
Rel(gateway, linksSvc, "Routes /v1/links")
Rel(gateway, analyticsSvc, "Routes /v1/analytics")
Rel(linksSvc, validatorSvc, "gRPC, internal, high frequency")
@enduml
```

### 7. Design Challenge

Quikn wants enterprise API access to create thousands of links per minute, and an internal admin dashboard that must call five internal services to render one page. Design the communication approach for both, justifying sync/async and REST/gRPC choices.

### 8. Solution and Discussion

**Enterprise bulk-creation API**: externally-facing, so REST/JSON remains right for public contract compatibility. But "thousands per minute" calls for request-async-reply (section 3), not one sync call per link: accept a batch, return 202 with a job ID, process via the async pipeline (Part 4), notify completion via webhook.

**Admin dashboard calling five services**: textbook API Gateway aggregation case. Rather than five separate frontend round trips, put an aggregation/BFF layer at the gateway that fans out calls in parallel and returns one combined response. gRPC is reasonable for these internal calls if called frequently across many internal tools; if low-frequency and single-consumer, internal REST is simpler and not worth the gRPC tooling cost. Lesson: gRPC's cost must be paid back by call volume, streaming need, or cross-team contract safety — don't reach for it just because it's "faster."

---
*Next: "Scalable Systems Design - Part 6: Designing for Failure"*
