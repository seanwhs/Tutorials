# Part 7: Async AsyncAPIClient (Concurrency with asyncio)

## Goal
Build an async twin of `APIClient` using `httpx.AsyncClient`, so we can fetch many resources concurrently (e.g. 50 GitHub users) in a fraction of the time a sequential sync loop would take — this is the payoff of choosing `httpx` over `requests` from Part 0.

## Why not just use the sync client in a thread pool?

You could (`asyncio.to_thread`), but a native async client avoids thread overhead entirely and integrates directly with `asyncio.gather`, async web frameworks (FastAPI, Starlette), and async task queues — which is where most 2026-era Python backend code lives. Since `httpx` supports both from one library, we get this "for free" by mirroring the sync client's structure almost exactly.

## `async_client.py`

```python
"""
Reusable asynchronous API client — mirrors client.py (APIClient) exactly,
but built on httpx.AsyncClient for concurrent request execution.

Rationale: Keeping the sync and async clients structurally identical
(same method names, same error translation, same retry policy) means
callers can switch between them with minimal code changes, and both
share the same mental model.
"""
import json
import logging
from types import TracebackType
from typing import Any, Optional, Type

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from config import settings
from exceptions import (
    APIClientError,
    APIConnectionError,
    APIResponseValidationError,
    APIStatusError,
    APITimeoutError,
)

logger = logging.getLogger(__name__)


class AsyncAPIClient:
    """Asynchronous HTTP client wrapper.

    Usage:
        async with AsyncAPIClient() as client:
            data = await client.get("/users/octocat")

        # Concurrent requests:
        async with AsyncAPIClient() as client:
            results = await asyncio.gather(
                client.get("/users/octocat"),
                client.get("/users/torvalds"),
            )
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        api_token: Optional[str] = None,
        timeout_seconds: Optional[float] = None,
    ) -> None:
        self._base_url = base_url or settings.base_url
        self._api_token = api_token or settings.api_token
        self._timeout = timeout_seconds or settings.timeout_seconds

        self._client = httpx.AsyncClient(
            base_url=self._base_url,
            timeout=self._timeout,
            headers=self._default_headers(),
        )
        logger.debug("AsyncAPIClient initialized with base_url=%s", self._base_url)

    def _default_headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self._api_token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "api-client-tutorial/1.0",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    async def __aenter__(self) -> "AsyncAPIClient":
        return self

    async def __aexit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None:
        await self.aclose()

    async def aclose(self) -> None:
        """Async equivalent of APIClient.close()."""
        await self._client.aclose()
        logger.debug("AsyncAPIClient connection pool closed")

    @retry(
        retry=retry_if_exception_type((APITimeoutError, APIConnectionError)),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=8),
        reraise=True,
    )
    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[dict[str, Any]] = None,
        json_body: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        try:
            logger.debug("-> %s %s params=%s", method, path, params)
            response = await self._client.request(method, path, params=params, json=json_body)
            self._raise_for_status(response)
            return self._parse_json(response)

        except httpx.TimeoutException as e:
            logger.warning("Timeout on %s %s: %s", method, path, e)
            raise APITimeoutError(f"Request to {path} timed out") from e

        except httpx.ConnectError as e:
            logger.warning("Connection error on %s %s: %s", method, path, e)
            raise APIConnectionError(f"Could not connect for {path}") from e

        except httpx.HTTPError as e:
            logger.error("Unexpected httpx error on %s %s: %s", method, path, e)
            raise APIClientError(f"Unexpected transport error for {path}") from e

    def _raise_for_status(self, response: httpx.Response) -> None:
        if response.is_success:
            return
        body_preview = response.text[:500]
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
        try:
            return response.json()
        except json.JSONDecodeError as e:
            logger.error("Failed to parse JSON response from %s: %s", response.url, e)
            raise APIResponseValidationError(
                f"Response from {response.url} was not valid JSON"
            ) from e

    async def get(self, path: str, *, params: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        return await self._request("GET", path, params=params)

    async def post(self, path: str, *, json_body: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        return await self._request("POST", path, json_body=json_body)
```

## Design notes

- **Structural mirror of `APIClient`**: same method names (`get`/`post`), same private helpers (`_raise_for_status`, `_parse_json`), same retry policy. The *only* differences are `async`/`await` keywords and `AsyncClient`/`aclose()`/`__aenter__`/`__aexit__` instead of their sync equivalents. This symmetry is intentional — it minimizes cognitive overhead when switching between the two.
- **`tenacity`'s `@retry` decorator works transparently on async functions** — no special async-retry library needed; tenacity detects the coroutine function and awaits correctly internally.
- **One `httpx.AsyncClient` per `AsyncAPIClient` instance, reused across requests** — exactly like the sync version, this pools connections. Creating a new `AsyncAPIClient()` (and thus new `AsyncClient()`) per request would defeat the purpose and add latency.
- **When to use async vs sync**: use `AsyncAPIClient` when calling from an already-async context (FastAPI route handlers, `asyncio.gather` for concurrent fan-out, background job workers built on asyncio). Use sync `APIClient` for simple scripts, Django (unless using async views), or CLI tools where there's no async event loop already running.

## Checkpoint — concurrent requests

```python
import asyncio
from async_client import AsyncAPIClient

async def main():
    async with AsyncAPIClient() as client:
        usernames = ["octocat", "torvalds", "gvanrossum"]
        results = await asyncio.gather(
            *(client.get(f"/users/{u}") for u in usernames)
        )
        for r in results:
            print(r["login"], "-", r.get("name"))

asyncio.run(main())
```

Expected output (roughly, actual names may vary):
```
octocat - The Octocat
torvalds - Linus Torvalds
gvanrossum - Guido van Rossum
```

All three requests fire concurrently rather than sequentially — with 3 requests the time savings are modest, but with 50+ requests the difference between sequential (~50 × latency) and concurrent (~1 × latency, bounded by connection limits) becomes dramatic.

## Troubleshooting

- **`RuntimeError: Event loop is closed`** — make sure you're calling `asyncio.run(main())` once at the top level, not nesting event loops (e.g. inside Jupyter, use `await main()` directly in a cell instead).
- **Forgot `await` on `client.get(...)`** — you'll get a coroutine object back instead of a dict, and `TypeError` when you try to index it. Async is "await all the way down."
- **Mixing sync `APIClient` and async `AsyncAPIClient` in the same call stack** — don't call sync `.get()` from inside an async function (it blocks the event loop); use the async client consistently within async code paths.

---

Next up: **Part 8 — Business Logic Layer: service.py (read operations)**. 
