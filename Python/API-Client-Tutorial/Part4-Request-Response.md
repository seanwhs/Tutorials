# Part 4: Pydantic v2 Request/Response Models

## Goal
Define strict, self-documenting schemas for everything that crosses the network boundary — both what we send (requests) and what we expect back (responses).

## Why validate responses at all? The API is already JSON...

JSON tells you the *syntax* is valid, not that the *shape* is what you expect. Without validation, a renamed field (`login` → `username`) or a type change (`id` becomes a string instead of an int) silently produces `None`/`KeyError` bugs deep in your business logic, often in production, hours after the API provider shipped a change. Pydantic validates at the boundary and raises immediately with a precise, human-readable error pointing at exactly which field broke.

## `models.py`

```python
"""
Pydantic v2 models for request/response validation.

Rationale: If GitHub changes a field name or type, this fails loudly at
the boundary (validation error) instead of silently propagating a
malformed dict deep into business logic. `model_config` with
extra="ignore" tolerates unknown fields the API may add later without
breaking us (forward compatibility), while still validating the fields
we DO care about strictly.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


# ---------- Response Models ----------

class GitHubUser(BaseModel):
    """Response model for GET /users/{username}."""
    model_config = ConfigDict(extra="ignore")

    id: int
    login: str
    name: Optional[str] = None
    email: Optional[str] = None
    public_repos: int = 0
    followers: int = 0
    html_url: HttpUrl
    created_at: datetime


class GitHubIssue(BaseModel):
    """Response model for POST /repos/{owner}/{repo}/issues."""
    model_config = ConfigDict(extra="ignore")

    id: int
    number: int
    title: str
    state: str
    html_url: HttpUrl
    created_at: datetime


# ---------- Request Models ----------

class CreateIssueRequest(BaseModel):
    """Request body model for creating an issue.

    Validating outbound payloads (not just responses) catches bugs like
    an empty title or an oversized body *before* a wasted network call.
    """
    title: str = Field(..., min_length=1, max_length=256)
    body: Optional[str] = Field(default=None, max_length=65536)
    labels: list[str] = Field(default_factory=list)

    def to_api_payload(self) -> dict:
        """Serialize to the exact JSON shape the API expects."""
        return self.model_dump(exclude_none=True)
```

## Design notes

- **`extra="ignore"` on response models**: GitHub (like most APIs) adds new fields to responses over time. If we used the Pydantic default (`extra="ignore"` is actually already the v2 default for `BaseModel`, but we set it explicitly for clarity/documentation), unknown new fields are silently dropped rather than raising — this is the correct behavior for *responses* since we don't control the provider's schema evolution.
- **`extra="forbid"` would be the right choice for request models** in stricter setups — it prevents you from accidentally sending a typo'd field name that the API silently ignores. We keep it implicit here but call it out as an option.
- **`HttpUrl` type**: Pydantic validates that `html_url` is actually a well-formed URL, not just any string. Catches malformed responses immediately.
- **`datetime` auto-parsing**: Pydantic v2 parses ISO-8601 strings (like GitHub's `"2024-01-15T10:30:00Z"`) directly into Python `datetime` objects — no manual `datetime.strptime` needed anywhere else in the codebase.
- **`Field(..., min_length=1, max_length=256)` on `title`**: validates *outbound* data before it ever hits the network. A request with an empty title fails instantly, locally, with a clear Pydantic error — instead of a wasted round-trip that comes back as a 422 from the server.
- **`to_api_payload()` method**: keeps serialization logic (excluding `None` fields, matching exact API field names) colocated with the model that owns it, rather than scattered as ad-hoc dict-building in the client or service layer.
- **Why not just use `dict`/`TypedDict`?** `TypedDict` gives you type *hints* but zero runtime validation — a bad response still passes type checkers silently since type hints aren't enforced at runtime. Pydantic actually validates data as it flows through your program.

## Checkpoint

Test model validation directly:

```python
from models import GitHubUser, CreateIssueRequest

# Valid data — should construct successfully
user = GitHubUser(
    id=1, login="octocat", html_url="https://github.com/octocat",
    created_at="2011-01-25T18:44:36Z"
)
print(user.login, user.created_at)

# Invalid data — should raise ValidationError
try:
    GitHubUser(id="not-an-int", login="x", html_url="not-a-url", created_at="garbage")
except Exception as e:
    print("Validation caught it:", e)

# Request validation
req = CreateIssueRequest(title="Bug: login page crashes", labels=["bug"])
print(req.to_api_payload())
# {'title': 'Bug: login page crashes', 'labels': ['bug']}

try:
    CreateIssueRequest(title="")  # too short
except Exception as e:
    print("Empty title rejected:", e)
```

## Troubleshooting

- **`ValidationError: Input should be a valid URL`** — GitHub's `html_url` was missing/malformed in test data; double check you're passing a full `https://...` string.
- **`datetime` parsing fails on a naive string** — make sure timestamps include timezone info (`Z` or `+00:00`); Pydantic v2 is strict about this by default.
- **Forgot `model_dump(exclude_none=True)`** and sent `{"body": null}` to an API that rejects explicit nulls — always use `.to_api_payload()` rather than `.model_dump()` directly for outbound requests.

---

Next up: **Part 5 — Building the Sync `APIClient` Core**. 
