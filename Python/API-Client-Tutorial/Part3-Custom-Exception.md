# Part 3: Custom Exception Hierarchy

## Goal
Define a small set of domain-specific exceptions so callers of our client never need to catch raw `httpx.*` or `pydantic.ValidationError` types directly — that would leak implementation details across layers.

## Why this matters

Imagine `service.py` (business logic) catching `httpx.ConnectTimeout`. If we ever swap `httpx` for another HTTP library, every call site using that exception type breaks. By translating all low-level failures into our own exceptions at the client boundary, the rest of the codebase only ever needs to know about *our* error types.

## `exceptions.py`

```python
"""
Custom exception hierarchy.

Rationale: Callers of the service layer should never need to catch
httpx.* or pydantic.ValidationError directly — that leaks implementation
details. We translate all low-level failures into a small, predictable
set of domain exceptions.
"""


class APIClientError(Exception):
    """Base class for all API client errors. Catch this to handle any
    failure from this client generically."""


class APITimeoutError(APIClientError):
    """Raised when a request times out (connect, read, or write timeout)."""


class APIConnectionError(APIClientError):
    """Raised on network-level failures (DNS resolution, connection refused,
    TLS handshake failure, etc.) — i.e. we never even got a response."""


class APIStatusError(APIClientError):
    """Raised when the API returns a 4xx/5xx status code.

    Carries the status_code and raw response body so callers can inspect
    the failure (e.g. distinguish a 404 "not found" from a 401 "bad auth"
    from a 429 "rate limited").
    """

    def __init__(self, status_code: int, message: str, body: str | None = None):
        self.status_code = status_code
        self.body = body
        super().__init__(f"API returned {status_code}: {message}")


class APIResponseValidationError(APIClientError):
    """Raised when the response body fails Pydantic validation or JSON
    parsing — i.e. we got a response, but it didn't look like what we
    expected (schema drift on the API provider's side, or a non-JSON
    error page from a proxy/load balancer)."""
```

## Design notes

- **Single common base (`APIClientError`)**: lets a caller write one broad `except APIClientError:` if they just want to catch "anything went wrong talking to this API", or catch specific subclasses for differentiated handling (e.g. retry on `APITimeoutError`, surface a user-facing "invalid input" message on a 422 `APIStatusError`).
- **`APIStatusError` carries `status_code` and `body`**: this is critical for debugging in production — logging just "API request failed" with no status code or body is nearly useless when triaging an incident.
- **`APIResponseValidationError` is distinct from `APIStatusError`**: a 200 response with a malformed body is a *different* failure mode (usually indicates the API's schema changed) than the API explicitly telling you "no" via a 4xx/5xx. Separating them makes alerting/monitoring more precise later.
- **No exception wraps a raw traceback string** — we use Python's built-in exception chaining (`raise X from e`, covered in Part 6) so the original `httpx` exception is still visible in tracebacks for debugging, while callers only need to `except` our types.

## Checkpoint

This file has no side effects to test yet — it's just pure exception classes. Confirm it imports cleanly:

```bash
python -c "from exceptions import APIClientError, APITimeoutError, APIConnectionError, APIStatusError, APIResponseValidationError; print('OK')"
```

We'll see these raised for real once `client.py` is built in Parts 5–6.

## Troubleshooting

- **`SyntaxError` on `str | None`** — this union syntax requires Python 3.10+. If you're on 3.9 or earlier, use `Optional[str]` from `typing` instead (and upgrade Python if possible — 3.11+ recommended per Part 0 prerequisites).

---

Next up: **Part 4 — Pydantic v2 Request/Response Models**. 
