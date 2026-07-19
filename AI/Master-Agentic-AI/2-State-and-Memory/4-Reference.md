# Phase 2 — Reference Section: Caching Semantics, Token Economics & Session Architecture

Optional deep-dive material — nothing in Phase 3 strictly requires reading this first, but it will deepen your understanding of the trade-offs behind the patterns just built.

## R2.1 `use cache` — What's Actually Being Cached, and For How Long

It's worth being precise about what the `'use cache'` directive guarantees, because "caching" means different things at different layers of a web stack, and conflating them leads to confusing bugs.

- **What we cached:** the *return value* of a specific async JavaScript function (`buildSystemPrompt()`), keyed implicitly by its inputs (in our case, there were none, so it's effectively a single cached value shared across all callers).
- **What we did NOT cache:** the HTTP response of any Route Handler, the model's actual completion output, or anything user-specific. Each of the sub-sections below only touches the *prompt construction* step, which — by design — should be identical for every user, since it contains no per-user data.
- **How long the cache lives:** By default, `use cache` entries persist for the lifetime of the caching layer Next.js manages (which, depending on your deployment target, can span multiple requests and multiple function invocations, not just a single one) until explicitly revalidated. In real deployments, you control this more precisely using `cacheLife()` and `cacheTag()` APIs (companions to `use cache`), which let you specify things like "revalidate this every 5 minutes" or "invalidate this specific cache entry whenever an admin updates configuration X." We didn't need those finer controls for our static, unchanging system prompt in this phase — but the moment your prompt construction depends on data that changes (e.g., a per-tenant configuration row in a database), you should reach for `cacheTag()` to be able to surgically invalidate just that entry when the underlying data changes, rather than relying purely on a time-based expiry.

**A critical rule:** never wrap per-user or per-request-sensitive data inside a `use cache` function unless you have explicitly keyed the cache by that user/request (e.g., by passing a user ID as an argument to the cached function, which Next.js incorporates into its cache key). If you accidentally cache something containing one user's private data inside a function with no per-user key, every subsequent caller — including completely different users — could receive that same cached, leaked data. This is a genuinely serious class of bug, and it's precisely why our `buildSystemPrompt()` deliberately contains zero user-specific content.

## R2.2 Token Estimation vs. Exact Tokenization

Our `estimateTokens()` heuristic (`characters ÷ 4`) is a reasonable, dependency-free approximation for English text, but it's worth understanding exactly where it diverges from real tokenizers, so you calibrate your trust in it correctly:

- **Real tokenizers use a fixed vocabulary of sub-word chunks** (a technique called Byte-Pair Encoding, or BPE, and its variants). Common whole words ("the", "computer") are often a single token; rare words, made-up words, and non-English text frequently split into several tokens.
- **Different providers use different tokenizers entirely.** Groq's Llama models, Google's Gemini models, and DeepSeek's models do not necessarily share an identical tokenizer — meaning the exact same input string can have a genuinely different real token count depending on which provider you send it to.
- **Numbers, punctuation-heavy text, and non-Latin scripts routinely break the ÷4 heuristic** far more than typical English prose does — for these categories the estimate is often noticeably too low, since many tokenizers spend more tokens per character on such content.

For our purposes — deciding *when* to trim a growing conversation before it risks a hard failure — a heuristic that's conservative and directionally correct is entirely sufficient, since our actual enforcement (`MAX_CONTEXT_TOKENS = 4000`, deliberately far under any real provider's ceiling) leaves generous headroom for the estimate being somewhat wrong. If you were building a system that needed to bill a customer to the exact token, or maximize context window usage down to the last token, you would instead use a provider-specific tokenizer package (e.g., `tiktoken`-style libraries exist for several model families) rather than this heuristic.

## R2.3 The Full Landscape of Context Management Strategies

Trimming the oldest messages first (what we built) is the simplest strategy in a broader family. It's useful to know the alternatives, since different applications benefit from different trade-offs:

| Strategy | How it works | Best for |
|---|---|---|
| **Oldest-first trimming** (what we built) | Drop earliest non-protected messages first | Simple chat-style agents where recency matters most |
| **Summarization compaction** | Periodically ask the model itself to compress older history into a short summary, then replace those messages with the summary | Long-running agents/conversations where early context still matters but doesn't need verbatim detail |
| **Sliding window with pinned facts** | Keep only the last N exchanges verbatim, but maintain a separate small structured "facts" object (e.g., extracted user preferences) that's always included regardless of window position | Systems where certain facts (like "user's favorite number is 27") must never be forgotten even after many turns |
| **Retrieval-based memory** | Store full history externally (e.g., in a vector database), and only pull back the most *relevant* past messages for the current query, rather than the most *recent* ones | Very long-running assistants where relevance matters more than recency — this connects directly to Phase 3's RAG material |

We'll touch on the retrieval-based approach conceptually in Phase 3, since it shares infrastructure with our retrieval-augmented generation work. For this course's scope, oldest-first trimming combined with hard-protected system/goal messages is a solid, production-reasonable default for a tool-using agent loop.

## R2.4 Why In-Memory `Map` Sessions Are a Development Convenience, Not a Production Architecture

We were explicit in the code comments, but it's worth restating clearly here: the `Map`-based session store in `lib/agent/sessionStore.js` has a hard limitation that will bite you the moment you deploy to most real serverless platforms (Vercel, AWS Lambda, etc.) — **these platforms routinely run multiple instances of your function simultaneously, and may spin up a fresh instance for any given request with no shared memory to any other instance.** A `Map` living in one instance's memory is invisible to every other instance. In practice this often manifests as: "the chat works fine sometimes, and randomly seems to forget everything other times" — which is a very confusing bug to chase if you don't already know why.

The fix, when you're ready to deploy for real, is to swap the internals of `sessionStore.js` for a call to a shared, network-accessible store — common choices include:
- **Redis** (e.g., Upstash's serverless-friendly Redis, which many Next.js + Vercel deployments use specifically because it's HTTP-based and works well in serverless environments)
- **A database table** (Postgres, etc.), keyed by session ID
- **A managed session/KV service** provided by your hosting platform

Because we deliberately kept `getSession(sessionId)`, `saveSession(sessionId, messages)`, and `deleteSession(sessionId)` as the *only* functions the rest of the application calls, swapping the internal implementation to any of the above requires changing exactly one file — nothing in `chat/route.js` or `reactLoop.js` needs to know or care where the data actually lives. This is the same "decoupling behind a stable interface" principle we'll formalize much more thoroughly in Phase 5's tool registry work.

## R2.5 Cookie Security Checklist

Since this part introduced our first cookie-based mechanism, it's worth summarizing the security-relevant flags we set, and why each one matters, as a standalone reference you can reuse on any future cookie you create in your own projects:

| Flag | What it does | Why we set it this way |
|---|---|---|
| `httpOnly: true` | Prevents JavaScript running in the browser from reading the cookie's value | Our session ID has no legitimate reason to be read by frontend JS; hiding it from JS entirely blocks a whole class of token-theft attacks via XSS |
| `secure: true` (in production) | Cookie is only ever sent over HTTPS connections | Prevents the session ID from being visible to anyone intercepting unencrypted traffic; disabled only in local dev, where `localhost` typically isn't served over HTTPS |
| `sameSite: 'lax'` | Restricts when the cookie is sent along with cross-site requests | A solid default balance — blocks the cookie from being attached to most cross-site requests (a core CSRF mitigation) while still allowing it to be sent on normal top-level navigation to your own site |
| `maxAge: 7 days` | Cookie automatically expires and is no longer sent after this duration | Matches our session store's own housekeeping expectations, and limits how long a stolen or stale cookie value would even remain useful if it were somehow compromised |

## R2.6 Async Request APIs — The Full Next.js 16 Picture

`cookies()` is one of several previously-synchronous Next.js APIs that became `async` (returning Promises) as of Next.js 15/16. The others you will encounter as this course progresses:

- **`headers()`** — must now be `await headers()` before calling `.get(headerName)` on it
- **`params`** (in dynamic route segments, e.g. `app/api/agent/[id]/route.js`) — the `params` object passed to your handler is now itself a Promise, requiring `const { id } = await params;`
- **`searchParams`** (in page components reading URL query strings) — likewise now async

The unifying reason across all of these: Next.js's App Router increasingly tries to prepare and render as much as it possibly can *before* committing to reading anything request-specific, to maximize opportunities for caching and static optimization. Treating access to request-specific data as an explicit asynchronous boundary is what makes that optimization possible under the hood. The practical rule for you as a developer, going forward for the rest of this course: **any time you see `cookies`, `headers`, or a dynamic route's `params`, reach for `await` reflexively** — it is never wrong to await something that happens to already be resolved, but it is very much a real bug to forget to await something that isn't.
