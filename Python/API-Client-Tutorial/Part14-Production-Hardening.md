# Part 14: Production Hardening & Deployment Checklist

## Goal
Close the gap between "works on my machine / passes tests" and "safe to run in production" — covering secrets management, rate limiting, retry risk on non-idempotent calls, timeouts, connection pool sizing, and monitoring.

## 1. Secrets management — beyond `.env`

`.env` files are fine for local development but should **never** be the source of truth in production:

- **Docker**: pass secrets via `docker run -e GITHUB_API_TOKEN=... ` or (better) Docker secrets / an orchestrator's secret store — never `COPY .env` into an image layer (it becomes permanently embedded in the image history, even if you delete it in a later layer).
- **Vercel/Netlify/similar**: use the platform's environment variable dashboard, marked "sensitive"/"encrypted" where offered.
- **AWS**: use Secrets Manager or Parameter Store (SecureString) and fetch at container startup, not baked into the image or a plain env var in the task definition where avoidable.
- **Kubernetes**: use `Secret` objects mounted as env vars or files, not ConfigMaps (which are not encrypted at rest by default in etcd unless you've enabled encryption).

`config.py`'s `Settings.from_env()` doesn't need to change for any of these — it just reads `os.getenv(...)`, agnostic to *how* the variable got set.

## 2. Rate limiting — respect the provider, protect yourself

Two directions matter:

- **Respect the provider's limits** (avoid getting your token banned/throttled): check response headers like `X-RateLimit-Remaining` / `Retry-After` and back off proactively, not just reactively after a 429. A simple addition to `_raise_for_status()`:
  ```python
  if response.status_code == 429:
      retry_after = response.headers.get("Retry-After")
      logger.warning("Rate limited. Retry-After: %s", retry_after)
  ```
  Then extend the `tenacity` retry policy to also retry on `APIStatusError` when `status_code == 429`, using `wait_exponential` or a custom wait function that respects `Retry-After` if present.

- **Protect your own downstream systems** from a burst of concurrent async calls overwhelming the provider or your own database — use a semaphore to cap concurrency:
  ```python
  semaphore = asyncio.Semaphore(10)  # max 10 concurrent requests

  async def fetch_with_limit(client, username):
      async with semaphore:
          return await client.get(f"/users/{username}")
  ```

## 3. Extending retry to cover 429/5xx (with the idempotency caveat from Part 9)

Recall Part 6 scoped retries to `APITimeoutError`/`APIConnectionError` only, deliberately avoiding retrying `APIStatusError` (which includes 429/5xx) because of the non-idempotent-write risk discussed in Part 9. For **GET requests specifically** (always safe to retry — they're read-only/idempotent by definition), you can safely add 429/5xx retry. One clean way: add a `idempotent: bool` parameter to `_request()` and only include `APIStatusError` in the retry condition when `idempotent=True`, defaulting `get()` to pass `idempotent=True` and `post()` to pass `idempotent=False` (or add an explicit `idempotency_key` parameter if the target API supports one, per Part 9's note on Stripe-style idempotency keys).

## 4. Timeout tuning

A single blanket `timeout_seconds` (Part 2's default of 10s) is a reasonable starting point, but `httpx` supports separate connect/read/write/pool timeouts for finer control:

```python
timeout = httpx.Timeout(connect=5.0, read=10.0, write=5.0, pool=5.0)
self._client = httpx.Client(base_url=self._base_url, timeout=timeout, headers=self._default_headers())
```

Slow endpoints (e.g. report-generation, bulk export) may need a longer `read` timeout while keeping `connect` tight (if we can't even establish a TCP connection in 5s, something is fundamentally wrong and waiting longer rarely helps).

## 5. Connection pool sizing

For high-throughput services, tune `httpx.Limits`:

```python
limits = httpx.Limits(max_connections=100, max_keepalive_connections=20)
self._client = httpx.Client(base_url=self._base_url, limits=limits, timeout=self._timeout, headers=self._default_headers())
```

Default limits (100 max connections, 20 keepalive) are reasonable for most workloads; raise `max_connections` if you're doing heavy concurrent async fan-out (Part 7) against an API that can handle it, and check the provider's own concurrent-connection recommendations.

## 6. Health checks & monitoring

- **Structured JSON logging** (Part 10) feeding a log aggregator (Datadog, CloudWatch, ELK) is your first line of observability — make sure `APIStatusError`'s `status_code` and truncated `body` actually get logged (they are, in `_raise_for_status`) so failures are diagnosable without reproducing them.
- **Metrics to track in production**: request count by status code, request latency (p50/p95/p99), retry count, and rate-limit-remaining (if the provider exposes it) — a lightweight addition using `time.monotonic()` around `self._client.request(...)` in `_request()` plus a metrics library (Prometheus client, StatsD, or your cloud provider's SDK) gets you most of this.
- **Circuit breaker for repeated failures**: if an API starts failing consistently (e.g. an outage), continuing to retry every request adds load to a struggling system and slows down your own app with piled-up timeouts. Consider a circuit-breaker library (e.g. `pybreaker`) wrapping `_request()` for critical dependencies — trips open after N consecutive failures, short-circuits calls for a cooldown period, then tries a test request to see if the API recovered.

## 7. Dependency & security hygiene

- Pin dependency versions in production (`pip freeze > requirements.lock` or use `pip-tools`/`poetry` lockfiles) so a transitive dependency update doesn't silently break behavior between deploys.
- Run `pip-audit` or GitHub's Dependabot to catch known CVEs in `httpx`/`pydantic`/`tenacity` and their transitive dependencies.
- Rotate API tokens on a schedule (many providers support this natively) and immediately if a token is ever accidentally logged or committed (check: does `_default_headers()`'s `Authorization` value ever get logged anywhere? It shouldn't — double check `logger.debug` calls near request construction don't dump full headers.)

## 8. Final pre-deploy checklist

- [ ] All secrets sourced from a real secret store, not `.env`, in production
- [ ] `configure_logging()` called once at true application startup, JSON format enabled (`LOG_JSON=true`)
- [ ] Retry policy reviewed for each write endpoint — idempotency risk acknowledged or mitigated
- [ ] Rate-limit headers checked and respected (proactive backoff, not just reactive)
- [ ] Timeouts tuned per-endpoint if response times vary significantly
- [ ] Connection pool limits sized appropriately for expected concurrency
- [ ] Dependencies pinned/locked; security scanning enabled in CI
- [ ] Tests (Part 12) run in CI on every commit/PR, not just locally
- [ ] Monitoring/alerting wired for elevated error rates or latency

## Troubleshooting

- **Token accidentally logged in plaintext** — rotate it immediately regardless of how it happened; audit `logger.debug`/`logger.info` calls near `_default_headers()` and request construction.
- **Production suddenly rate-limited after a deploy that added async concurrency** — add a semaphore (see #2 above) to cap concurrent outbound requests; this is one of the most common regressions when moving from sync to async fan-out without limiting.
- **Retries amplifying an outage** — this is exactly what a circuit breaker (#6) protects against; short-term mitigation is to lower `stop_after_attempt` or temporarily disable retries via a feature flag during a known provider outage.

---

Next up: **Conclusion — Recap & Where to Go Next** (the final part in the series). 
