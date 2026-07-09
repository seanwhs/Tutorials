# Part 6: Sync APIClient Request Methods, Error Handling & Retries

## Goal
Add `get()`/`post()` (and a private `_request()` they share) to `APIClient`, with full try/except error translation into our custom exceptions from Part 3, plus automatic retry-with-backoff via `tenacity` for transient failures.

## What "transient" means (and why we only retry some errors)

Not all failures should be retried. A `429 Too Many Requests` or a `503 Service Unavailable` or a connection timeout is often **transient** — retrying after a short backoff frequently succeeds. A `404 Not Found` or `422 Unprocessable Entity` is **not transient** — the resource genuinely doesn't exist / the request is genuinely malformed, and retrying just wastes time and hammers the API. We configure `tenacity` to retry only on the specific exception types that represent transient failures.

## Add this to `client.py` (continuing from Part 5)

```python
# --- add these imports at the top of client.py ---
import json
from typing import Any

from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

# --- add these methods inside the APIClient class, after close() ---

    @retry(
        # Only retry on errors we've classified as transient. A 404 or 422
        # (APIStatusError with a 4xx that isn't 429) will NOT be retried —
        # see _raise_for_status below for how status codes map to
        # retryable vs non-retryable exceptions.
        retry=retry_if_exception_type((APITimeoutError, APIConnectionError)),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=8),
        reraise=True,
    )
    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[dict[str, Any]] = None,
        json_body: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """Low-level request executor shared by get()/post()/etc.

        Translates every failure mode into one of our custom exceptions
        (see exceptions.py) so callers never see raw httpx exceptions.
        """
        try:
            logger.debug("-> %s %s params=%s", method, path, params)
            response = self._client.request(method, path, params=params, json=json_body)
            self._raise_for_status(response)
            return self._parse_json(response)

        except httpx.TimeoutException as e:
            # Covers ConnectTimeout, ReadTimeout, WriteTimeout, PoolTimeout
            logger.warning("Timeout on %s %s: %s", method, path, e)
            raise APITimeoutError(f"Request to {path} timed out") from e

        except httpx.ConnectError as e:
            # DNS failure, connection refused, TLS handshake failure, etc.
            logger.warning("Connection error on %s %s: %s", method, path, e)
            raise APIConnectionError(f"Could not connect for {path}") from e

        except httpx.HTTPError as e:
            # Catch-all for any other httpx-level failure not covered above.
            logger.error("Unexpected httpx error on %s %s: %s", method, path, e)
            raise APIClientError(f"Unexpected transport error for {path}") from e

    def _raise_for_status(self, response: httpx.Response) -> None:
        """Translate 4xx/5xx status codes into APIStatusError.

        We treat 429 (rate limited) and 5xx as effectively transient by
        also raising APIConnectionError-compatible... actually we keep
        them as APIStatusError, but a caller wanting auto-retry on 429/5xx
        can catch APIStatusError and check status_code >= 500 or == 429.
        For this tutorial we keep retry scoped to network-level failures
        (Part 14 covers extending retry to include 429/503 explicitly).
        """
        if response.is_success:
            return
        body_preview = response.text[:500]  # avoid logging huge bodies
        logger.error(
            "HTTP %s for %s %s — body: %s",
            response.status_code, response.request.method, response.request.url, body_preview,
        )
        raise APIStatusError(
            status_code=response.status_code,
            message=response.reason_phrase,
            body=body_preview,
        )

    def _parse_json(self, response: httpx.Response) -> dict[str, Any]:
        """Safely parse the response body as JSON.

        A 200 status with a non-JSON body (e.g. an HTML error page from a
        proxy/load balancer in front of the real API) should NOT crash
        with a raw json.JSONDecodeError leaking out of this class.
        """
        try:
            return response.json()
        except json.JSONDecodeError as e:
            logger.error("Failed to parse JSON response from %s: %s", response.url, e)
            raise APIResponseValidationError(
                f"Response from {response.url} was not valid JSON"
            ) from e

    # ---------- Public request methods ----------

    def get(self, path: str, *, params: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        """Perform a GET request and return the parsed JSON body as a dict."""
        return self._request("GET", path, params=params)

    def post(self, path: str, *, json_body: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        """Perform a POST request with a JSON body, return parsed JSON response."""
        return self._request("POST", path, json_body=json_body)
```

> Remember to add `from exceptions import APIResponseValidationError` to the imports at the top of `client.py` alongside the ones already there from Part 5.

## Design notes

- **`_request()` is private; `get()`/`post()` are the public API**: all the shared error-handling/retry logic lives in one place. Adding `put()`, `patch()`, `delete()` later is a one-line addition each, all getting the same error handling for free.
- **`@retry` decorator from tenacity**: declarative — `stop_after_attempt(3)` (try up to 3 times total), `wait_exponential(multiplier=1, min=1, max=8)` (1s, 2s, 4s... capped at 8s between attempts), `reraise=True` (after exhausting retries, re-raise the *original* exception rather than tenacity's own `RetryError` wrapper — keeps our exception hierarchy clean for callers).
- **`retry_if_exception_type((APITimeoutError, APIConnectionError))`**: only these two exception types trigger a retry. A `APIStatusError` (e.g. a 404) is raised and propagates immediately — retrying a 404 three times with backoff would just be three wasted round trips for a resource that will never appear.
- **Exception chaining (`raise X from e`)**: preserves the original `httpx` exception as `__cause__` on our custom exception. This means `logger.exception(...)` or an unhandled traceback still shows the *root cause* (e.g. the actual `httpx.ConnectTimeout` details) for debugging, while callers only need to catch our custom type.
- **`response.text[:500]` truncation**: prevents logs from being flooded by a huge HTML error page or a large JSON error body; 500 chars is plenty to diagnose most issues.
- **`_parse_json()` isolated from `_raise_for_status()`**: a response can be a 200 *and* still have a malformed body (rare, but happens with buggy proxies/CDNs) — keeping these as separate steps means each failure mode maps to a distinct, precise exception type.

## Checkpoint

```python
from client import APIClient

with APIClient() as client:
    data = client.get(f"/users/octocat")
    print(data["login"], data["id"])
```

Expected output:
```
octocat 583231
```

Now test the error path with a nonexistent user:

```python
from client import APIClient
from exceptions import APIStatusError

with APIClient() as client:
    try:
        client.get("/users/this-user-definitely-does-not-exist-12345")
    except APIStatusError as e:
        print("Caught expected error:", e.status_code, e)
        # Caught expected error: 404 API returned 404: Not Found
```

## Troubleshooting

- **Retries happening on 404s** — double check `retry_if_exception_type` only lists `APITimeoutError`/`APIConnectionError`, not `APIStatusError`.
- **`RetryError` leaking out instead of your custom exception** — make sure `reraise=True` is set on the `@retry` decorator.
- **Rate limited (403 with `X-RateLimit-Remaining: 0`)** — unauthenticated GitHub requests are capped at 60/hour per IP; add a real token in `.env` (Part 2) to raise this to 5,000/hour.
- **`json.JSONDecodeError` not caught** — make sure you imported `json` at the top of `client.py`.

---

Next up: **Part 7 — Async AsyncAPIClient (concurrency with asyncio)**. 
