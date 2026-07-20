# Quiz: Phase 2 — State Persistence, Caching & Context Windows

---

**Q1.** A colleague wants to add a `use cache` directive to a new function called `buildPersonalizedGreeting(userId)`, which fetches a specific user's name and preferences from a database and returns a custom greeting string. What's dangerous about doing this without any further changes, and how does this connect to the warning given about `buildSystemPrompt()` in this phase's Reference Section?



---

**Q2.** The token trimming function removes messages in pairs of two, always starting from the oldest non-protected messages. Why would removing a single message at a time (rather than pairs) risk producing a broken transcript?



---

**Q3.** Why does the session store's `getSession()` function check `Date.now() - entry.lastAccessedAt > SESSION_TTL_MS` and actively delete expired entries, rather than just letting old sessions sit in the `Map` forever since memory is cheap?



---

**Q4.** Explain, in your own words, why `cookies()` needed to become an `async` function in Next.js 16, and what concrete bug would result from forgetting to `await` it in `resolveSessionId()`.



---

**Q5.** A teammate proposes swapping the in-memory session `Map` for Redis before deploying to production, but wants to keep calling `getSession()`/`saveSession()` exactly as they're currently used throughout `chat/route.js`. Is this achievable without touching `chat/route.js` at all? Why was the session store deliberately designed this way?



---

**Q6.** Why does the course set the session cookie with `httpOnly: true`, and what specific class of attack does this protect against that `secure: true` does not?
