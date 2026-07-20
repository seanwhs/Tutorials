# Appendix E: Master Glossary

Every technical term introduced across the entire series, defined in one place, alphabetically. Each entry notes where the concept was first introduced, so you can jump back to the full explanation and code if you need more depth.

---

**Adapter (Provider Adapter)** — A small function whose only job is translating one AI provider's native SDK request/response shape into a common, normalized shape the rest of the application understands. *Introduced: Phase 7, Part 3.*

**Agentic RAG** — A retrieval approach where the system judges its own search result quality using a second model call, and rewrites its query and retries if the results are deemed insufficient — as opposed to running a search once and accepting whatever comes back. *Introduced: Phase 3, Part 2.*

**API Key (Application-level)** — A shared secret a client must present (via the `x-api-key` header) to access the agent's endpoints, enforced globally by middleware before any route handler runs. *Introduced: Phase 5, Part 3.*

**`AbortController`** — A standard Web API that provides a `signal` object which can be handed to a `fetch`-based request, plus an `.abort()` method to cancel that request on demand. Used for both per-call timeouts and whole-loop deadlines. *Introduced: Phase 1, Part 3.*

**Circuit Breaker** — A resilience pattern that tracks a provider's recent consecutive failures and temporarily stops sending it traffic ("opens the circuit") for a cool-down period, rather than continuing to retry a provider that's clearly, systemically down. *Introduced: Phase 7, Part 3.*

**Context Window** — The maximum number of tokens a model can accept across an entire request (system prompt + conversation history + new input) before it hard-fails. *Introduced: Phase 2, Part 2.*

**Cookie (Session Cookie)** — A small piece of data the server asks the browser to store and automatically resend on future requests, used here to carry a stable session ID across otherwise-stateless serverless invocations. *Introduced: Phase 2, Part 3.*

**Cost Ledger** — A session-scoped, accumulating record of real dollar cost incurred across every turn of a multi-turn conversation. *Introduced: Phase 3, Part 4.*

**DAN ("Do Anything Now")** — A historically real, well-documented family of jailbreak prompts that attempt to convince a model to role-play as an unrestricted persona with no safety guidelines; used generically to refer to persona-based jailbreak attempts. *Introduced: Phase 4, Part 2.*

**Deadline (Whole-Loop Deadline)** — A single hard ceiling on the total wall-clock time of an entire reasoning loop, enforced via one shared `AbortController` signal threaded through every step and retry, as distinct from a per-step timeout. *Introduced: Phase 7, Part 2.*

**Edge Runtime** — The lightweight, fast-starting execution environment Next.js Middleware runs in by default, supporting standard Web APIs but not the full Node.js API surface (no direct filesystem access, limited native module support). *Introduced: Phase 5, Reference Section.*

**Embedding (Vector Embedding)** — A representation of text as a list of numbers capturing its meaning, used to find semantically similar content even without shared exact wording — the mechanism this course deliberately avoided in favor of vectorless retrieval for small/structured datasets. *Introduced: Phase 3, Part 1.*

**Event Bus** — A structured, per-request, append-only record that independent agent stages publish findings to and read prior findings from, without needing direct references to each other's code. *Introduced: Phase 6, Part 3.*

**Exponential Backoff** — A retry strategy where each successive retry attempt waits roughly twice as long as the previous one, to avoid overwhelming an already-struggling or rate-limited service. *Introduced: Phase 7, Part 1.*

**Fail Closed / Fail Open** — Two opposing design defaults for what a system should do when a safety-checking mechanism itself breaks: fail closed means block/reject by default (used for security guardrails); fail open means proceed/accept by default (used for the retrieval quality judge). *Introduced: Phase 3, Part 2; formalized in Phase 3, Reference Section.*

**Fallback Route** — A guaranteed final response path that engages whenever the main reasoning loop fails to converge naturally (stuck loop, malformed JSON, timeout, deadline exceeded), ensuring the user always receives a real, usable answer rather than `null`. *Introduced: Phase 1, Part 3.*

**Failover** — Automatically routing a request to a backup provider when the primary provider fails, is rate-limited, or is circuit-broken. *Introduced: Phase 7, Part 3.*

**Jailbreak** — A user prompt specifically crafted to bypass a model's intended behavioral guardrails (e.g., "ignore all previous instructions"). *Introduced: Phase 4, Part 2.*

**Jitter** — A small amount of randomness added to a calculated backoff delay, spreading out concurrent retries so they don't all collide again on the exact same schedule. *Introduced: Phase 7, Part 1.*

**JSON Mode (`response_format: { type: 'json_object' }`)** — A provider API option that constrains model output to guaranteed-valid JSON syntax, used instead of fragile free-text/regex parsing to extract the model's reasoning and chosen action. *Introduced: Phase 1, Part 2.*

**Key-Value Lookup** — A retrieval pattern for exact-identifier data (e.g., an order ID) where there's no ranking involved — either the exact record exists or it doesn't, as distinct from relevance-ranked document search. *Introduced: Phase 3, Part 3.*

**MCP (Model Context Protocol)** — An open standard for how AI applications expose tools/resources to language models in a decoupled, standardized way; this course built an in-process architecture inspired by MCP's design philosophy without implementing its full client-server transport protocol. *Introduced: Phase 5, Part 1.*

**Middleware** — A special Next.js file (`middleware.js`) that intercepts every matching request before any Route Handler runs, used here for global API key enforcement and request tracing. *Introduced: Phase 5, Part 3.*

**Multi-Agent Cascade** — An architecture where multiple narrowly-scoped, specialized agents each analyze the same input independently, potentially fanning out concurrently and later being combined by a synthesis stage. *Introduced: Phase 6.*

**Normalization (Provider Normalization)** — Translating multiple providers' genuinely different SDK response shapes into one single, common shape so the rest of the application never needs to know which vendor actually answered a request. *Introduced: Phase 7, Part 3.*

**PII (Personally Identifiable Information)** — Sensitive personal data such as emails, phone numbers, Social Security Numbers, and credit card numbers, detected via regex and masked before being sent to any model provider. *Introduced: Phase 4, Part 1.*

**Prompt Injection** — An attack where a user's input attempts to override or manipulate a system's underlying instructions, distinct from a jailbreak in that it can target any instruction-following behavior, not just persona restrictions. *Introduced: Phase 4, Part 2.*

**ReAct (Reason + Act)** — A pattern where a model alternates between reasoning (Think), taking an action (Act), and observing the result (Observe), repeating until it reaches a goal — as opposed to answering in one uninterrupted pass. *Introduced: Phase 1, Part 2.*

**Redaction** — Replacing detected sensitive text with a clear placeholder (e.g., `[EMAIL_REDACTED]`) rather than blocking the request outright, since the underlying data itself (not the request's intent) is the concern. *Introduced: Phase 4, Part 1.*

**Regex (Regular Expression)** — A pattern-matching language used throughout the course's guardrails to detect text of a particular shape (email addresses, phone numbers, known jailbreak phrasings). *Introduced: Phase 4, Part 1.*

**Route Handler** — A file named `route.js` inside a folder under `app/` that automatically becomes a live API endpoint at that folder's path, with exported functions named after HTTP verbs (`GET`, `POST`, etc.). *Introduced: Phase 1, Part 1.*

**Session Store** — A store, external to any single request's memory, that holds conversation history keyed by session ID, allowing serverless functions (which have no memory between invocations) to maintain multi-turn context. *Introduced: Phase 2, Part 3.*

**`safeParse()`** — A Zod validation method that never throws; it always returns an explicit `{ success, data }` or `{ success, error }` object to be checked, matching this course's consistent preference for checked failure paths over exception-driven control flow. *Introduced: Phase 4, Part 3.*

**Serverless Function** — A unit of backend code (like a Next.js Route Handler) that has no guaranteed memory between separate invocations and may run on a different physical instance each time, requiring external state management for anything that needs to persist. *Introduced: Phase 2, Part 3.*

**Token** — The basic unit of text a language model actually processes — roughly ¾ of an English word on average, though exact tokenization varies by provider and model. *Introduced: Phase 2, Part 2.*

**Token Budget / Trimming** — Actively managing the total estimated token count of a growing conversation transcript, discarding the oldest non-protected exchanges first to stay under a model's context window limit. *Introduced: Phase 2, Part 2.*

**Tool (in the MCP-inspired sense)** — A self-describing unit combining a name, a description, a Zod input schema, and a handler function, registered centrally and invoked only through a uniform registry interface. *Introduced: Phase 5, Part 1.*

**Tool Registry** — The central object managing registration, discovery (`listToolDescriptions()`), and uniform, validated execution (`execute()`) of every tool in the system. *Introduced: Phase 5, Part 1.*

**`use cache`** — A Next.js 16 directive that caches the return value of an async function, computing it once and reusing the stored result across subsequent calls until invalidated. *Introduced: Phase 2, Part 1.*

**Vectorless Retrieval** — Direct, structured data access matched to the shape of the underlying data (keyword scoring for documents, exact lookup for key-value records, live calls for external APIs) rather than converting everything into vector embeddings regardless of fit. *Introduced: Phase 3, Part 1.*

**Write Action (Write Tool)** — A tool that mutates state (e.g., `cancelOrder`) rather than only reading it, treated as a distinct, deployment-gatable category separate from read-only tools. *Introduced: Phase 5, Part 2.*

**Zod** — A runtime schema validation library used throughout the course both to validate incoming request bodies and, more critically, to guarantee that LLM-generated structured output actually matches an exact, trustworthy shape before being used downstream. *Introduced: Phase 1, Part 1 (installed); first used Phase 4, Part 3.*
