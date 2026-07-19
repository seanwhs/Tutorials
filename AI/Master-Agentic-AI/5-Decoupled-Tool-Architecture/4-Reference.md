# Phase 5 — Reference Section: MCP Protocol Depth, Middleware Runtime & Registry Extension Patterns

Optional deep-dive material — nothing in Phase 6 requires reading this first.

## R5.1 How Close Is What We Built to "Real" MCP?

It's worth being precise about the gap between our MCP-inspired, in-process architecture and the actual, published Model Context Protocol specification, so you know exactly what to expect if you adopt the real protocol in a future project.

The genuine MCP standard defines a full **client-server protocol** with its own transport layer (commonly JSON-RPC 2.0 messages over stdio for local integrations, or HTTP/SSE for remote ones). An MCP **server** exposes its tools and resources over this protocol; an MCP **client** (embedded inside an AI application/host) discovers and calls them across that transport boundary — meaning the tool provider and the AI application can genuinely be separate processes, potentially written in entirely different languages, running on different machines.

What we built captures the *design philosophy* MCP promotes — standardized tool description, strict schemas, decoupled handlers, uniform discovery/invocation — but everything runs **in-process**, inside the same Next.js server, with no actual JSON-RPC messages or separate server process involved. This was a deliberate teaching choice: the architectural lessons (decoupling, schema-first design, uniform dispatch) transfer directly, without the added complexity of standing up and debugging a separate protocol server before you've even internalized why the pattern matters.

If you outgrow the in-process version — for example, you want a shared "tools server" usable by multiple different applications, or you want tools implemented in a different language/runtime than your main app — migrating to real MCP is a natural next step, and the mental model translates almost one-to-one: your `defineTool()` objects become MCP tool definitions exposed by an MCP server; your `ToolRegistry.execute()` calls become MCP client requests over the protocol's transport.

## R5.2 Edge Runtime vs. Node.js Runtime — What Middleware Can and Can't Do

Next.js Middleware runs in the **Edge Runtime** by default — a deliberately restricted execution environment optimized for extremely fast cold starts and global distribution close to users, at the cost of not supporting the *full* Node.js API surface. Concretely, this means:

- **Available:** `fetch`, `Request`/`Response`, `crypto.randomUUID()`, standard Web APIs (all of which our middleware used) — this is why our middleware code works without any special configuration.
- **Not available (by default):** direct file-system access (`fs`), many native Node.js modules, and most third-party npm packages that depend on Node-specific APIs internally.

This has a very practical consequence: **you generally cannot use a full database driver or a heavy SDK directly inside middleware.** If you needed, say, a real per-customer API key lookup against a database (rather than our single shared-secret comparison), you would typically either call a separate lightweight API route from middleware, use an Edge-compatible database client (several providers now offer these specifically for this use case), or move that specific check into a Node.js-runtime Route Handler instead of middleware. Next.js does allow opting individual middleware into the full Node.js runtime via configuration in newer versions, but the Edge default exists precisely because middleware is meant to be a fast, lightweight gate — if you find yourself needing heavy, slow logic inside middleware, that's often a signal the check belongs one layer further in instead.

## R5.3 Registry Extension Patterns Worth Knowing

A few natural extensions to the `ToolRegistry` pattern, beyond what we built, that come up frequently in real systems:

```js
// Per-tool timeout overrides — some tools (like a slow external API call)
// may need a longer allowance than others.
export function defineTool({ name, description, inputSchema, handler, timeoutMs = 10000 }) {
  // ...same validation as before...
  return { name, description, inputSchema, handler, timeoutMs };
}

// Per-tool rate limiting — preventing a single tool from being called too
// many times within one loop run, distinct from our global step ceiling.
class ToolRegistry {
  async execute(toolName, rawInput, callCountsThisRun = {}) {
    const callsSoFar = callCountsThisRun[toolName] || 0;
    const tool = this._tools.get(toolName);
    if (tool?.maxCallsPerRun && callsSoFar >= tool.maxCallsPerRun) {
      return { ok: false, errorType: 'TOOL_CALL_LIMIT_EXCEEDED', message: `"${toolName}" has been called too many times this run.` };
    }
    // ...proceed with normal execution...
  }
}

// Tool categories/tags for filtering which tools are exposed to which
// AGENT (relevant once Phase 6 introduces multiple specialized agents,
// each of which may only need a SUBSET of the full tool registry).
export function defineTool({ name, description, inputSchema, handler, tags = [] }) {
  // ...
  return { name, description, inputSchema, handler, tags };
}
// Usage: registry.listToolDescriptions({ tag: 'read-only' })
```

That last pattern — tagging tools and filtering by tag — is directly relevant to what's coming next: Phase 6 introduces multiple specialized agents running in parallel, and it's often desirable for each specialized agent to only see the subset of tools relevant to its specialty, rather than the entire registry. Keep this extension pattern in mind; we'll reference it again.

## R5.4 Middleware Security Checklist Reference

A consolidated checklist for any middleware-based authentication layer you build in future projects, based on the principles applied in Part 3:

| Principle | What we did |
|---|---|
| Never trust query parameters for secrets | Required the API key via a header (`x-api-key`), not a URL query string |
| Fail closed on server misconfiguration | Explicitly checked for a missing `AGENT_API_KEY` and blocked everything with a clear `500`, rather than allowing an ambiguous comparison to accidentally pass |
| Scope middleware narrowly | Used `matcher: '/api/agent/:path*'` rather than running auth checks against every route in the entire application, including public pages |
| Attach traceability metadata | Generated a `x-request-id` per request, enabling correlation between middleware logs and downstream route handler logs for the same request |
| Log rejected attempts | Logged both missing-key and misconfiguration failures server-side, which is essential for detecting abuse patterns or brute-force attempts over time |

## R5.5 Toward Multi-Tenant API Keys (A Preview, Not Implemented Here)

Our single shared-secret approach (`AGENT_API_KEY`) is appropriate for a single-tenant application or internal tool, but a real multi-customer SaaS product would typically need **per-customer API keys**, each tied to a specific account, with its own usage tracking and revocation capability. The natural evolution path, for when you need it:

1. Store hashed API keys (never plaintext) in a database table, associated with a customer/account ID.
2. In middleware, look up the provided key's hash against that table (likely via a fast Edge-compatible lookup, or a call out to a dedicated auth-check API route, per the Edge Runtime constraints discussed in R5.2).
3. Attach the resolved customer ID as a header (similar to how we attached `x-request-id`), so downstream route handlers know *which* customer is making the request — enabling the per-session cost ledger from Phase 3 to become a genuine per-*customer* billing ledger.

This is a natural next step once you're ready to move this course's architecture toward a real multi-tenant product, but was intentionally out of scope for this phase, which focused on establishing the *mechanism* of global enforcement rather than a full account management system.
