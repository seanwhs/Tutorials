# Part 12: Unit Testing with Mocked HTTP (pytest + respx)

## Goal
Write real unit tests for `service.py` and `client.py` that never make actual network calls — using `respx` (an `httpx`-native mocking library) plus plain dependency-injection mocks, both demonstrating the testability payoff promised back in Part 0.

## Why this matters ("testability" isn't just a buzzword)

Tests that hit the real GitHub API are slow, flaky (network blips, rate limits), and can have side effects (Part 9's `create_issue` really creates issues!). Because we built `APIClient`/`AsyncAPIClient` as injectable dependencies and kept `service.py` free of any direct network code, we can test business logic (validation, error translation, correct URL construction) completely offline, in milliseconds, deterministically.

## Step 1 — add test-only dependencies

```txt
# requirements-dev.txt
-r requirements.txt
pytest>=8.2.0
pytest-asyncio>=0.23.0
respx>=0.21.0
```

```bash
pip install -r requirements-dev.txt
```

> **Why a separate `requirements-dev.txt`?** Production deployments (Part 14) should install the smallest possible dependency set. Test tooling has no business being installed on a production server.

## Step 2 — `tests/test_service.py` (mocking at the service boundary — simplest, fastest)

```python
"""
Unit tests for service.py using a plain MagicMock in place of APIClient.

This style of test doesn't touch httpx at all — it verifies that
GitHubService correctly calls client.get()/post() with the right
arguments, and correctly validates/translates the response. It's the
fastest and simplest test style, appropriate for most service-layer logic.
"""
from unittest.mock import MagicMock

import pytest
from pydantic import ValidationError

from exceptions import APIResponseValidationError, APIStatusError
from models import GitHubUser
from service import GitHubService


@pytest.fixture
def fake_client() -> MagicMock:
    """A stand-in for APIClient with no real network access."""
    return MagicMock()


@pytest.fixture
def service(fake_client: MagicMock) -> GitHubService:
    return GitHubService(fake_client)


def test_get_user_success(service: GitHubService, fake_client: MagicMock) -> None:
    fake_client.get.return_value = {
        "id": 583231,
        "login": "octocat",
        "name": "The Octocat",
        "public_repos": 8,
        "followers": 100,
        "html_url": "https://github.com/octocat",
        "created_at": "2011-01-25T18:44:36Z",
    }

    user = service.get_user("octocat")

    assert isinstance(user, GitHubUser)
    assert user.login == "octocat"
    assert user.id == 583231
    # Verify the SERVICE called the client with the correct path — this
    # is what proves get_user() knows the right URL shape.
    fake_client.get.assert_called_once_with("/users/octocat")


def test_get_user_schema_mismatch_raises_validation_error(
    service: GitHubService, fake_client: MagicMock
) -> None:
    # Simulate a response missing required fields (schema drift on
    # GitHub's side, or a typo in our model).
    fake_client.get.return_value = {"id": "not-an-int", "login": "x"}

    with pytest.raises(APIResponseValidationError):
        service.get_user("x")


def test_get_user_propagates_status_errors(
    service: GitHubService, fake_client: MagicMock
) -> None:
    # Simulate the client raising a 404 — the service layer should NOT
    # swallow this; it should propagate unchanged.
    fake_client.get.side_effect = APIStatusError(status_code=404, message="Not Found")

    with pytest.raises(APIStatusError) as exc_info:
        service.get_user("nonexistent")
    assert exc_info.value.status_code == 404


def test_create_issue_rejects_empty_title_before_network_call(
    service: GitHubService, fake_client: MagicMock
) -> None:
    with pytest.raises(ValidationError):
        service.create_issue(owner="me", repo="test-repo", title="")

    # Critically: the client's post() should NEVER have been called,
    # proving validation happens locally before any network I/O.
    fake_client.post.assert_not_called()
```

## Step 3 — `tests/test_client.py` (mocking at the HTTP transport boundary — more thorough)

```python
"""
Integration-style tests for APIClient itself, using respx to intercept
httpx requests at the transport level. This verifies our actual HTTP
request construction, header injection, retry behavior, and error
translation — a layer deeper than test_service.py.
"""
import httpx
import pytest
import respx

from client import APIClient
from exceptions import APIStatusError, APITimeoutError


@respx.mock
def test_get_success() -> None:
    respx.get("https://api.github.com/users/octocat").mock(
        return_value=httpx.Response(200, json={
            "id": 1, "login": "octocat", "html_url": "https://github.com/octocat",
            "created_at": "2011-01-25T18:44:36Z",
        })
    )

    with APIClient(base_url="https://api.github.com", api_token="fake-token") as client:
        data = client.get("/users/octocat")

    assert data["login"] == "octocat"


@respx.mock
def test_get_404_raises_api_status_error() -> None:
    respx.get("https://api.github.com/users/ghost").mock(
        return_value=httpx.Response(404, json={"message": "Not Found"})
    )

    with APIClient(base_url="https://api.github.com", api_token="fake-token") as client:
        with pytest.raises(APIStatusError) as exc_info:
            client.get("/users/ghost")

    assert exc_info.value.status_code == 404


@respx.mock
def test_timeout_is_retried_then_raises() -> None:
    # Simulate the endpoint always timing out — verifies our @retry
    # decorator attempts 3 times (per Part 6's stop_after_attempt(3))
    # before finally raising APITimeoutError.
    route = respx.get("https://api.github.com/users/slow").mock(
        side_effect=httpx.TimeoutException("simulated timeout")
    )

    with APIClient(base_url="https://api.github.com", api_token="fake-token") as client:
        with pytest.raises(APITimeoutError):
            client.get("/users/slow")

    assert route.call_count == 3  # confirms retry actually happened 3x
```

## Step 4 — run the tests

```bash
pytest tests/ -v
```

Expected output:
```
tests/test_service.py::test_get_user_success PASSED
tests/test_service.py::test_get_user_schema_mismatch_raises_validation_error PASSED
tests/test_service.py::test_get_user_propagates_status_errors PASSED
tests/test_service.py::test_create_issue_rejects_empty_title_before_network_call PASSED
tests/test_client.py::test_get_success PASSED
tests/test_client.py::test_get_404_raises_api_status_error PASSED
tests/test_client.py::test_timeout_is_retried_then_raises PASSED

======================== 7 passed in 0.42s ========================
```

Notice the **entire suite runs in under half a second** with zero real network calls — this is only possible because of the dependency-injection and layering decisions made all the way back in Parts 5 and 8.

## Design notes

- **Two levels of test granularity**: `test_service.py` mocks at the `APIClient` boundary (fast, tests business logic only), `test_client.py` mocks at the `httpx` transport boundary via `respx` (slightly slower/more setup, but verifies the actual HTTP request shape, headers, retry counts). Both are valuable; most projects lean heavily on the former with a handful of the latter for critical paths.
- **`respx` over manually monkeypatching `httpx`**: `respx` is purpose-built for mocking `httpx` traffic — it intercepts at the transport layer so real `httpx.Client`/`AsyncClient` code paths (including our retry decorator!) run exactly as in production, just against a fake server response instead of the real network.
- **`assert_not_called()` / `assert_called_once_with(...)`**: these aren't just "did it work" assertions — they prove *behavioral contracts* (e.g. "validation happens before any network call", "the URL path is constructed correctly"), which is what actually catches regressions when someone refactors `service.py` later.
- **Testing the retry count (`route.call_count == 3`)**: this directly verifies the `tenacity` configuration from Part 6 behaves as documented, rather than trusting it blindly.

## Troubleshooting

- **`respx` tests hang or make a real network call** — make sure `@respx.mock` decorates the test function (or use `with respx.mock:` as a context manager) — without it, respx doesn't intercept anything.
- **`pytest-asyncio` errors on async tests** — add `asyncio_mode = "auto"` to a `pytest.ini` or `pyproject.toml` `[tool.pytest.ini_options]` section, or mark async test functions explicitly with `@pytest.mark.asyncio`.
- **`fake_client.get.assert_called_once_with(...)` fails on path formatting** — double check for trailing slashes or f-string typos in `service.py`'s endpoint paths.

---

Next up: **Part 13 — Generalizing This Template to Any API**. 
