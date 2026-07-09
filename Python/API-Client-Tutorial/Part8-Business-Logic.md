# Part 8: Business Logic Layer — service.py (Read Operations)

## Goal
Introduce `service.py`, the layer that translates raw `APIClient` dict responses into validated Pydantic model instances, and exposes domain-meaningful functions like `get_user(username)` instead of generic `get(path)`.

## Why a separate service layer at all?

`APIClient` deliberately knows nothing about "users" or "issues" — it only knows how to send HTTP requests and return dicts. If we called `client.get("/users/octocat")` directly from application code (a Flask route, a CLI command, a Celery task) all over the codebase, two problems emerge: (1) every call site has to remember to manually validate the dict against `GitHubUser`, and (2) the URL path `/users/{username}` is duplicated everywhere instead of defined once. The service layer fixes both — it's the single place where "what a user is" and "how to fetch one" are defined.

## `service.py`

```python
"""
Business logic layer — sits between raw APIClient calls and application
code. Responsible for:
  1. Knowing which endpoint paths correspond to which domain concepts.
  2. Validating raw dict responses into Pydantic models.
  3. Exposing a clean, typed, domain-specific function signature to callers.

Application code (main.py, a web route, a CLI command, etc.) should only
ever import from here — never reach into client.py directly.
"""
import logging

from pydantic import ValidationError

from client import APIClient
from exceptions import APIResponseValidationError
from models import GitHubUser

logger = logging.getLogger(__name__)


class GitHubService:
    """Domain-level operations against the GitHub API.

    Takes an APIClient (or AsyncAPIClient — see Part 9 for the async
    variant) via dependency injection rather than constructing its own,
    so tests can inject a mock/fake client (see Part 12).
    """

    def __init__(self, client: APIClient) -> None:
        self._client = client

    def get_user(self, username: str) -> GitHubUser:
        """Fetch a single GitHub user profile by username.

        Raises:
            APIStatusError: if the user doesn't exist (404) or auth fails.
            APITimeoutError / APIConnectionError: on network issues.
            APIResponseValidationError: if GitHub's response doesn't match
                our expected GitHubUser schema.
        """
        logger.info("Fetching GitHub user: %s", username)
        raw_data = self._client.get(f"/users/{username}")
        return self._validate_user(raw_data, username)

    def _validate_user(self, raw_data: dict, username: str) -> GitHubUser:
        """Validate a raw dict response into a GitHubUser model.

        Isolated as its own method so both sync and (later) async
        variants of "get a user" share identical validation logic —
        avoids duplicating this try/except in every method that returns
        a GitHubUser.
        """
        try:
            return GitHubUser.model_validate(raw_data)
        except ValidationError as e:
            logger.error("Response schema mismatch for user '%s': %s", username, e)
            raise APIResponseValidationError(
                f"GitHub user response for '{username}' did not match expected schema"
            ) from e
```

## Design notes

- **Constructor takes an `APIClient` instance (dependency injection)**, rather than the service creating its own client internally. This is the single biggest thing that makes this layer *testable* — in Part 12 we inject a fake/mocked client that returns canned data with zero real network calls.
- **`model_validate()` vs. `GitHubUser(**raw_data)`**: `model_validate()` is the Pydantic v2 idiomatic way to construct a model from a dict (it's what `**raw_data` unpacking effectively does under the hood, but `model_validate` is the documented public API and handles some edge cases around aliasing/nested models more robustly).
- **Wrapping `pydantic.ValidationError` into our own `APIResponseValidationError`**: consistent with the exception hierarchy design from Part 3 — even a validation failure happening *in the service layer* (not the client layer) still surfaces as one of our domain exceptions, not a raw Pydantic error leaking to application code.
- **`_validate_user()` as a private helper**: as this service grows (Part 9 adds issue creation, and a real project might add "list repos", "get organization", etc.), each public method stays a thin 2-3 line wrapper: fetch raw data → validate → return. All the "what happens if validation fails" logic lives in one place per model type.
- **Logging at INFO for the "fetching X" action, ERROR for validation failures**: this gives you an audit trail of what was requested (INFO, cheap, useful for debugging "why did this get called") while reserving ERROR for things that actually need attention.

## Checkpoint

```python
from client import APIClient
from service import GitHubService

with APIClient() as client:
    service = GitHubService(client)
    user = service.get_user("octocat")
    print(f"{user.login} (#{user.id}) — {user.public_repos} public repos")
    print("Profile:", user.html_url)
```

Expected output:
```
octocat (#583231) — 8 public repos
Profile: https://github.com/octocat
```

Now confirm validation errors surface correctly by monkey-patching a bad response (simulated schema drift):

```python
from unittest.mock import MagicMock
from service import GitHubService
from exceptions import APIResponseValidationError

fake_client = MagicMock()
fake_client.get.return_value = {"id": "not-an-int", "login": "x"}  # missing html_url, created_at too

service = GitHubService(fake_client)
try:
    service.get_user("x")
except APIResponseValidationError as e:
    print("Caught schema mismatch as expected:", e)
```

## Troubleshooting

- **`APIResponseValidationError` raised on a real, valid user** — double-check `models.GitHubUser` required fields against the actual GitHub API response for that endpoint (GitHub occasionally omits `email` for privacy — it's already `Optional` in our model, so that's fine, but if GitHub adds a *new required-looking* field mismatch, adjust the model).
- **Confusing this with `client.get()`** — remember: application code should call `service.get_user(...)`, never `client.get("/users/...")` directly. If you find yourself importing `client.py` outside of `service.py` and `main.py`'s setup code, that's a sign the abstraction is being bypassed.

---

Next up: **Part 9 — Business Logic Layer: service.py (Write Operations + Validation)**. 
