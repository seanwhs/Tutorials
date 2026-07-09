# Part 5: Building the Sync APIClient Core

## Goal
Build the skeleton of `APIClient`: constructor, session/connection pooling via a persistent `httpx.Client`, shared headers, base URL, and lifecycle management (context manager support so connections are always cleaned up).

## Why a class instead of module-level functions?

A class lets us hold a **single persistent `httpx.Client`** for the lifetime of the object. `httpx.Client` internally pools TCP connections — reusing it across many requests (instead of creating a new `httpx.Client()` per call) avoids repeated TCP/TLS handshake overhead and is dramatically faster under load. It also gives us a natural place to store shared config (base URL, auth headers, timeout) once instead of passing it to every function call.

## `client.py` (Part 1 of 2 — core/lifecycle; request methods come in Part 6)

```python
"""
Reusable synchronous API client — transport layer only.

Rationale: This class knows HOW to talk HTTP (auth headers, base URL,
connection pooling, timeouts, retries, error translation). It knows
NOTHING about what a "user" or "issue" means — that's the service
layer's job (see service.py, Parts 8-9). This separation is what makes
the client reusable for any API and easily mockable in tests.
"""
import logging
from types import TracebackType
from typing import Optional, Type

import httpx

from config import settings
from exceptions import (
    APIClientError,
    APIConnectionError,
    APIStatusError,
    APITimeoutError,
)

logger = logging.getLogger(__name__)


class APIClient:
    """Synchronous HTTP client wrapper.

    Usage:
        with APIClient() as client:
            data = client.get("/users/octocat")

    The `with` block ensures the underlying connection pool is closed
    cleanly even if an exception is raised mid-request.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        api_token: Optional[str] = None,
        timeout_seconds: Optional[float] = None,
    ) -> None:
        # Allow overriding settings per-instance (useful for testing against
        # a staging URL, or injecting a fake token in unit tests) while
        # defaulting to the global settings singleton from config.py.
        self._base_url = base_url or settings.base_url
        self._api_token = api_token or settings.api_token
        self._timeout = timeout_seconds or settings.timeout_seconds

        self._client = httpx.Client(
            base_url=self._base_url,
            timeout=self._timeout,
            headers=self._default_headers(),
        )
        logger.debug("APIClient initialized with base_url=%s", self._base_url)

    def _default_headers(self) -> dict[str, str]:
        """Headers sent on every request.

        Centralizing this means auth, Accept, and User-Agent headers can
        never drift between different call sites — there's only one
        place they're defined.
        """
        return {
            "Authorization": f"Bearer {self._api_token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "api-client-tutorial/1.0",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    # ---------- Context manager support ----------
    # Lets callers use `with APIClient() as client:` so the connection
    # pool is always closed, even if an exception occurs inside the block.

    def __enter__(self) -> "APIClient":
        return self

    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None:
        self.close()

    def close(self) -> None:
        """Explicitly close the underlying connection pool.

        Safe to call even if already closed. Always call this (or use
        the `with` statement) to avoid leaking sockets in long-running
        processes.
        """
        self._client.close()
        logger.debug("APIClient connection pool closed")
```

## Design notes

- **Constructor accepts optional overrides**: `base_url`, `api_token`, and `timeout_seconds` all default to the global `settings` singleton but can be overridden per-instance. This is essential for **testability** — in Part 12 we'll instantiate an `APIClient` pointing at a mock transport without touching real environment variables.
- **`_default_headers()` as a separate method**: keeps header construction in one place. If GitHub requires a new header version bump (they do — `X-GitHub-Api-Version`), you change it in exactly one spot.
- **Context manager (`__enter__`/`__exit__`)**: the idiomatic Python pattern for resource cleanup. `httpx.Client` holds open sockets; forgetting to close it in a long-running server process is a real resource leak. The `with` statement guarantees `close()` runs even if the code inside raises.
- **Why store `httpx.Client` as `self._client` (private/underscore)?**: signals to callers "this is an implementation detail, use the public methods (`get`, `post`, etc. — coming in Part 6) instead of reaching into the raw client directly."
- **Not yet implemented here (coming in Part 6)**: the actual `get()`/`post()` methods, retry logic, and try/except error translation. We're deliberately building this incrementally so each concept (lifecycle vs. request/error handling) is easy to absorb separately.

## Checkpoint

```python
from client import APIClient

with APIClient() as client:
    print("Client created, base_url:", client._base_url)
print("Client closed — no error means clean shutdown")
```

Expected output:
```
Client created, base_url: https://api.github.com
Client closed — no error means clean shutdown
```

If you enable debug logging (Part 10 covers this properly), you'll also see the `"APIClient initialized..."` and `"...connection pool closed"` debug lines.

## Troubleshooting

- **`AttributeError: 'APIClient' object has no attribute '_client'`** — make sure `__init__` fully ran; this usually means an exception was thrown before `self._client = httpx.Client(...)` executed (e.g. missing env var from Part 2 — check that error first).
- **Client "works" without ever calling `close()`** — yes, Python's garbage collector *may* eventually close it, but don't rely on this in production; always use `with` or call `.close()` explicitly (e.g. in a `finally` block or a framework's shutdown hook).

---

Next up: **Part 6 — Sync APIClient Request Methods, Error Handling & Retries**.
