# Part 9: Business Logic Layer — service.py (Write Operations + Validation)

## Goal
Extend `GitHubService` with a write operation — creating an issue — demonstrating request-body validation (Part 4's `CreateIssueRequest`) flowing all the way through to a validated response model.

## Why write operations deserve extra care

Read operations (GETs) are idempotent and low-risk — running one twice by accident just fetches the same data again. Write operations (POST/PUT/PATCH/DELETE) are not idempotent by default — accidentally submitting a form twice can create two duplicate GitHub issues, charge a customer twice, etc. This part shows validating input *before* it leaves the process, and structuring the code so retries (from Part 6) don't accidentally double-submit.

## Add this to `service.py` (continuing from Part 8)

```python
# --- add these imports at the top of service.py ---
from models import CreateIssueRequest, GitHubIssue

# --- add this method inside the GitHubService class ---

    def create_issue(
        self,
        owner: str,
        repo: str,
        title: str,
        body: str | None = None,
        labels: list[str] | None = None,
    ) -> GitHubIssue:
        """Create a new issue in a GitHub repository.

        Args:
            owner: repository owner (user or org), e.g. "octocat"
            repo: repository name, e.g. "Hello-World"
            title: issue title (required, 1-256 chars — validated below)
            body: issue description (optional, markdown supported)
            labels: label names to apply (optional)

        Raises:
            pydantic.ValidationError: if title/body/labels fail local
                validation (e.g. empty title) — raised BEFORE any network
                call is made, saving a wasted round trip.
            APIStatusError: e.g. 404 if owner/repo doesn't exist, 401/403
                if the token lacks 'repo' scope, 410 if issues are disabled.
            APIResponseValidationError: if GitHub's response doesn't match
                our expected GitHubIssue schema.
        """
        # Build and validate the request model FIRST. If this raises,
        # we never touch the network — cheap, fast failure.
        request = CreateIssueRequest(title=title, body=body, labels=labels or [])

        logger.info("Creating issue in %s/%s: %s", owner, repo, title)
        raw_data = self._client.post(
            f"/repos/{owner}/{repo}/issues",
            json_body=request.to_api_payload(),
        )
        return self._validate_issue(raw_data, owner, repo)

    def _validate_issue(self, raw_data: dict, owner: str, repo: str) -> GitHubIssue:
        try:
            return GitHubIssue.model_validate(raw_data)
        except ValidationError as e:
            logger.error("Response schema mismatch for issue in '%s/%s': %s", owner, repo, e)
            raise APIResponseValidationError(
                f"GitHub issue response for '{owner}/{repo}' did not match expected schema"
            ) from e
```

## A note on retries and non-idempotent writes (important!)

Look back at Part 6's `@retry` decorator on `APIClient._request()` — it only retries on `APITimeoutError` and `APIConnectionError`, which represent cases where **we never received a confirmed response** (e.g. the request timed out, or the connection dropped). This is deliberate:

- If GitHub received the POST and created the issue, but the response was lost in transit before we read it (rare, but possible), a retry *could* theoretically create a duplicate issue.
- In practice, for most REST APIs, a connection-level failure (as opposed to a successful-but-slow-to-return response) usually means the request never reached the server at all — so retrying is safe *most* of the time, but not guaranteed 100% for non-idempotent operations.
- **For APIs where this risk matters** (payments, order creation, etc.), the correct fix is an **idempotency key** — a client-generated unique ID sent in a header (e.g. `Idempotency-Key: <uuid>`) that the server uses to detect and safely ignore duplicate submissions. Stripe, for example, supports this natively. GitHub's issue-creation endpoint does not support idempotency keys, so for this specific tutorial endpoint, be aware that automatic retries on POST carry a small theoretical duplicate-creation risk. Part 14 covers this trade-off and how to disable retries selectively for a given call if you want zero risk.

## Design notes

- **Validate the request model *before* calling `self._client.post(...)`**: a `ValidationError` on `title=""` is raised locally, instantly, with zero network I/O. This is both faster and cheaper (no wasted API rate-limit quota) than letting the server reject it with a 422.
- **`labels: list[str] | None = None` with `labels or []` fallback**: avoids the classic Python mutable-default-argument bug (`def f(x=[])`) while still giving callers a convenient `None` default to mean "no labels."
- **Symmetric structure with `get_user`**: `create_issue` follows the exact same shape — build/validate input, call client, validate output via a private `_validate_*` helper. This consistency makes the codebase predictable: once you've read one service method, you understand the pattern for all of them.
- **Docstring documents every exception type that can propagate**: this is a deliberate best practice for library-style code — callers (and your future self) shouldn't have to read the implementation to know what to catch.

## Checkpoint

> Requires a real GitHub token with `repo` scope, and a repo you own (using your own throwaway test repo is recommended — this really will create an issue!).

```python
from client import APIClient
from service import GitHubService

with APIClient() as client:
    service = GitHubService(client)
    issue = service.create_issue(
        owner="your-username",
        repo="your-test-repo",
        title="Test issue from API client tutorial",
        body="This issue was created automatically to verify Part 9 works.",
        labels=["test"],
    )
    print(f"Created issue #{issue.number}: {issue.html_url}")
```

Expected output:
```
Created issue #1: https://github.com/your-username/your-test-repo/issues/1
```

Now confirm local validation catches bad input without any network call:

```python
try:
    service.create_issue(owner="x", repo="y", title="")  # empty title
except Exception as e:
    print("Caught validation error before any network call:", e)
```

## Troubleshooting

- **`401 Unauthorized`** — token missing/expired; regenerate in GitHub Settings → Developer settings.
- **`403 Forbidden` / `Resource not accessible by personal access token`** — fine-grained token doesn't have `Issues: Read and write` permission on that specific repo; check token scope configuration.
- **`404 Not Found` on a repo you're sure exists** — fine-grained tokens must be explicitly granted access to that repo (or "all repos") at creation time.
- **`410 Gone`** — the target repo has issues disabled in its settings.

---

Next up: **Part 10 — Logging Configuration & Observability**. 
