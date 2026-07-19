# Phase 5, Part 3: Global Middleware — API Key Enforcement & Securing Agent Entry Points

## The Target

Every guardrail we've built so far (Zod validation, injection detection, PII redaction) lives *inside* individual route handlers — which means a developer adding a brand-new endpoint tomorrow could easily forget to wire one of these protections in. In this part, we build a single **Next.js Middleware** file at the project root that intercepts **every** request to our `/api/agent/*` routes globally, before they ever reach an individual route handler. It will enforce API key authentication, attach a request ID for tracing, and apply basic rate-limit headers — all in one centralized place that no individual route can accidentally bypass.

## The Concept

Think about the difference between a building where every single office has its own separate lock and key policy set by whoever happens to work there, versus a building with one security desk at the main entrance that every visitor must pass through before reaching *any* office. The first approach means security is only as strong as the least careful office — miss one door, and you have a hole. The second approach means there's exactly one place to get security right, and every single room automatically benefits, including rooms that don't exist yet.

**Next.js Middleware** is that main security desk. It's a special file — `middleware.js`, placed at your project root — that runs *before* the Next.js router even decides which Route Handler or page to invoke. Because it executes at this earliest possible point, it's the ideal place for concerns that should apply *uniformly, globally, without exception* — authentication, rate limiting, request logging, geographic restrictions, and similar cross-cutting policies. Crucially, middleware runs in Next.js's **Edge Runtime** by default — a lightweight, fast-starting execution environment (not full Node.js) — which is well-suited for exactly this kind of quick "should this request even proceed" check, but which also means it has some API restrictions worth knowing about (no raw file-system access, a restricted subset of Node APIs), a distinction we'll touch on in this phase's Reference Section.

We're deliberately building **API key enforcement** as our middleware's first responsibility, because it's the most fundamental gate of all: *before we even care what a request is asking for, does it have permission to talk to us at all?* This is exactly the kind of check that should never depend on any individual route handler remembering to implement it — it should be structurally impossible to reach any agent endpoint without passing through this check first, which is precisely what placing it in middleware guarantees.

## The Implementation

### Step 1 — Define a valid API key and add a request-tracing configuration

**File: `.env.local`** *(add this line)*
```bash
# A shared secret clients must present to use the agent API. In a real
# multi-tenant system, you'd validate against a database of per-customer
# keys rather than a single shared secret — see the Reference Section for
# a discussion of that upgrade path.
AGENT_API_KEY=demo-secret-key-change-me-in-production
```

### Step 2 — The global middleware file

Middleware must live at the project root (same level as `app/`), not inside `app/` itself.

**File: `middleware.js`**
```js
import { NextResponse } from 'next/server';

/**
 * Runs on EVERY request matching the `matcher` config below, BEFORE any
 * individual Route Handler executes. This is the single, structural
 * enforcement point for cross-cutting concerns that must apply uniformly
 * to every agent endpoint, with no possibility of an individual route
 * accidentally forgetting to implement them.
 */
export function middleware(request) {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  // --- CHECK 1: API key enforcement -----------------------------------------
  // We accept the key via a standard "x-api-key" header — never via a URL
  // query parameter, since query strings are far more likely to end up
  // logged in browser history, proxy logs, or server access logs in plain text.
  const providedKey = request.headers.get('x-api-key');
  const expectedKey = process.env.AGENT_API_KEY;

  if (!expectedKey) {
    // FAIL CLOSED: if the server itself isn't even configured with an
    // expected key, that's a deployment misconfiguration — we must not
    // silently allow every request through as if authentication were
    // intentionally disabled. Block everything and log loudly.
    console.error('[middleware] AGENT_API_KEY is not configured on the server. Blocking all requests.');
    return NextResponse.json(
      { success: false, error: 'Server misconfiguration: API authentication is not set up.' },
      { status: 500 }
    );
  }

  if (!providedKey || providedKey !== expectedKey) {
    console.warn(`[middleware] [${requestId}] Rejected request with missing/invalid API key from ${request.headers.get('x-forwarded-for') || 'unknown IP'}.`);
    return NextResponse.json(
      { success: false, error: 'Missing or invalid API key. Provide a valid "x-api-key" header.' },
      { status: 401 } // 401 Unauthorized — distinct from 403 (which we use for policy violations after auth succeeds)
    );
  }

  // --- CHECK 2: attach tracing metadata for downstream observability --------
  // We generate the response via NextResponse.next(), which means "proceed
  // to the actual route handler" — but we attach extra headers first, which
  // flow through to both the eventual response AND are readable by the
  // route handler itself via request.headers.
  const response = NextResponse.next();
  response.headers.set('x-request-id', requestId);
  response.headers.set('x-processed-by', 'agent-gateway-middleware');

  // Simple, transparent latency tracking for this middleware layer's own
  // overhead — useful during development to confirm this layer itself
  // isn't introducing unexpected delay.
  const middlewareLatencyMs = Date.now() - startedAt;
  response.headers.set('x-middleware-latency-ms', String(middlewareLatencyMs));

  console.log(`[middleware] [${requestId}] Authorized request to ${request.nextUrl.pathname} (${middlewareLatencyMs}ms).`);

  return response;
}

/**
 * The matcher config controls WHICH request paths this middleware runs
 * against. We deliberately scope it to only our agent API routes — running
 * expensive checks (or requiring an API key at all) against, say, static
 * assets or unrelated pages would be wasteful and often nonsensical.
 */
export const config = {
  matcher: '/api/agent/:path*',
};
```

> **Why check for a missing `AGENT_API_KEY` on the server *before* checking the client's provided key?** This ordering directly reflects the fail-closed principle from Phase 4: if the server's own configuration is broken (the expected key was never set — perhaps someone forgot to configure `.env.local` in a new deployment), the *safe* failure is to reject everything, loudly, with a clear `500` server-misconfiguration error — never to accidentally fall into a state where `providedKey !== undefined` evaluates in some unexpected way that lets requests through unauthenticated. Checking this first and returning immediately eliminates any chance of that ambiguity.

### Step 3 — Update our test commands to include the API key

Since every single one of our previous `curl` examples throughout this course will now fail with a `401` unless they include the header, this is a good moment to explicitly note the new required format going forward:

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"message": "What is 12 times 12?"}' \
  | python3 -m json.tool
```

### Step 4 — Read the request ID inside a route handler, to prove the middleware's data actually flows through

**File: `app/api/agent/whoami/route.js`**
```js
import { NextResponse } from 'next/server';
import { headers } from 'next/headers';

export async function GET() {
  // NEXT.JS 16 ASYNC API: headers() must be awaited, exactly like cookies()
  // from Phase 2 — this reads the SAME headers object the middleware
  // populated moments earlier, proving data set in middleware is genuinely
  // visible to the route handler that runs after it.
  const headersList = await headers();
  const requestId = headersList.get('x-request-id');
  const processedBy = headersList.get('x-processed-by');

  return NextResponse.json({
    message: 'This response came from a route handler that ran AFTER middleware.',
    requestId,
    processedBy,
  });
}
```

## The Verification

### Test 1 — Confirm requests without an API key are rejected at the middleware layer

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" http://localhost:3000/api/agent/whoami
```
**Expected:**
```json
{"success":false,"error":"Missing or invalid API key. Provide a valid \"x-api-key\" header."}
HTTP_STATUS:401
```

Confirm an incorrect key is equally rejected:
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -H "x-api-key: wrong-key" http://localhost:3000/api/agent/whoami
```
**Expected:** the same `401` response.

### Test 2 — Confirm a correct API key allows the request through, with tracing headers attached

```bash
curl -s -i -H "x-api-key: demo-secret-key-change-me-in-production" http://localhost:3000/api/agent/whoami
```

**Expected:** a `200 OK` response. Check the response headers (visible via `-i`) for `x-request-id`, `x-processed-by: agent-gateway-middleware`, and `x-middleware-latency-ms` — confirming the middleware successfully attached its metadata. The JSON body itself should show the *same* `requestId` value, proving the route handler successfully read data that middleware set moments earlier:

```json
{
    "message": "This response came from a route handler that ran AFTER middleware.",
    "requestId": "f47ac10b-...",
    "processedBy": "agent-gateway-middleware"
}
```

### Test 3 — Confirm the full chat pipeline still works correctly with the API key included

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"message": "What time is it right now?"}' \
  | python3 -m json.tool
```
Confirm a normal `"success": true` response, proving the middleware layer integrates cleanly in front of the entire existing guardrail + agent pipeline without disrupting any of it.

### Test 4 — Confirm the fail-closed misconfiguration path

Temporarily comment out or remove the `AGENT_API_KEY` line from `.env.local`, restart the server, and try any request:
```bash
curl -s -w "\nHTTP_STATUS:%{http_code}\n" -H "x-api-key: anything" http://localhost:3000/api/agent/whoami
```
**Expected:** a `500` response with `"Server misconfiguration: API authentication is not set up."`, and a corresponding `console.error` in your terminal — confirming the system fails safely and loudly rather than silently disabling authentication when misconfigured. Restore `AGENT_API_KEY` in `.env.local` and restart the server before continuing.

With all four tests passing, you've established a genuine global security perimeter: every single request to any current or future `/api/agent/*` endpoint is now structurally required to pass through API key enforcement, request tracing, and fail-closed misconfiguration handling — with zero possibility of an individual route handler being written in a way that accidentally bypasses these protections, since the check happens before any route handler code runs at all.
