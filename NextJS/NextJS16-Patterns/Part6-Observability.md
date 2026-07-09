## Part 6: Observability and Structured Logging

**Anti-Pattern:** Scattered, unstructured `console.log`/`console.error` calls with no correlation between a user-reported bug and the server log that explains it — unqueryable free text, leftover debug logs shipping to prod.

**Next.js 16 Pattern:**
- **Structured logging facade** (`lib/observability/logger.ts`) — mirrors the Repository/Facade pattern: one seam (`Logger` interface) instead of raw `console.*` scattered everywhere, emits parseable JSON.
- **Correlation IDs via `cache()`** — a per-request `requestId` (or Vercel's `x-vercel-id`), memoized once per request, threaded through repositories → actions → facades → error boundaries.
- **`withLogging` higher-order wrapper** — auto-instruments Server Actions (start/success/failure/duration) by inspecting the `ActionResult<T>` union, fully generic so type inference survives.
- **Layer-by-layer logging guidance** — what to log in repositories vs actions vs facades vs error boundaries.

**Type-Safe Implementation:** `LogContext` restricted to serializable primitives (no raw `Error`/db rows), `LogLevel` as a string union (not bare `string`), fully generic `withLogging<TArgs, TResult>`.

**Architect's Note:** structured logging overhead vs `console.log` simplicity, correlation ID propagation payoff, log volume/sampling/cost trade-offs, and Edge Runtime logging constraints (swap logger implementation, keep interface stable — same Facade philosophy as Part 4).

**Code Appendix** includes: `Logger`/`LogContext` types, `JsonLogger` implementation, `request-context.ts` with `getRequestId`/`getOrCreateRequestId`, generic `withLogging`, and wired-in usage examples across the Part 1 repository, Part 2 Server Action, Part 4 payments facade, and Part 4 `error.tsx` (pairing `error.digest` with the custom `requestId`).
