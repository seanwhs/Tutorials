
## Part 5: Testing Strategy 

**Anti-Pattern:** Testing everything through full component renders with global `fetch` mocking — slow, brittle, and business logic (buried in `useEffect`/click handlers) can't be tested in isolation.

**Next.js 16 Pattern — a testing pyramid mapped to the architecture built in Parts 1-4:**

| Layer | Test type | Tool |
|---|---|---|
| Repositories, Server Actions, Facades | Unit test | Vitest |
| Async Server Components | Integration test | RTL (await the component directly) |
| Suspense fallbacks / error boundaries | Integration test | RTL (forced throws/pending promises) |
| Full browser flows | E2E | Playwright |

**Type-Safe Implementation:** Test doubles (`FakeProjectRepository`) implement the *same interface* as production classes — TypeScript fails the build if the fake drifts from the real contract.

**Architect's Note:** Why fakes beat inline `fetch` mocking, why the pyramid is intentionally unit-heavy/E2E-light, and why Vercel cache-behavior tests should be a separate post-deploy smoke suite (flaky-by-nature, shouldn't block fast CI feedback).

**Code Appendix** includes full runnable snippets: `FakeProjectRepository`, unit tests for `archiveProject`, integration test for `ProjectStats` (async Server Component), Suspense/`ErrorBoundary` tests, a mocked-Stripe facade test, and two Playwright specs (URL state survives refresh, optimistic archive flow).
