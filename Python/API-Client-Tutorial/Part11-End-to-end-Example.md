# Part 11: Putting It All Together — main.py End-to-End Example

## Goal
Wire up everything from Parts 1–10 into a runnable `main.py` that demonstrates the full stack: logging configured at startup, sync client used via the service layer, error handling at the application boundary, and a bonus async concurrent-fetch example.

## `main.py`

```python
"""
End-to-end example usage of the API client stack built in Parts 1-10.

This is the ONLY place in the project that:
  1. Calls configure_logging() (application entry point — Part 10)
  2. Directly imports both client.py AND service.py to wire them together
  3. Catches our custom exceptions at the top level and decides what to
     do about them (log and exit, log and continue, etc.)

Everything else (client.py, service.py) stays reusable/importable by
other entry points (a web server, a CLI, a test suite) without dragging
in this file's specific "print to console" behavior.
"""
import asyncio
import logging
import sys

from async_client import AsyncAPIClient
from client import APIClient
from exceptions import APIClientError, APIStatusError
from logging_config import configure_logging
from service import GitHubService

logger = logging.getLogger(__name__)


def run_sync_example() -> None:
    """Fetch a single user using the sync client + service layer."""
    with APIClient() as client:
        service = GitHubService(client)
        try:
            user = service.get_user("octocat")
        except APIStatusError as e:
            # Specific handling: e.g. a 404 might mean "prompt the user to
            # check the username", vs. a 401 meaning "check your token".
            if e.status_code == 404:
                logger.warning("User not found.")
            elif e.status_code in (401, 403):
                logger.error("Authentication failed — check GITHUB_API_TOKEN.")
            else:
                logger.error("Unexpected API error: %s", e)
            return
        except APIClientError as e:
            # Catch-all for anything else our client can raise
            # (timeouts, connection errors, schema validation failures).
            logger.error("Request failed: %s", e)
            return

        print(f"\n[Sync] {user.login} (#{user.id})")
        print(f"  Name: {user.name}")
        print(f"  Public repos: {user.public_repos}")
        print(f"  Profile: {user.html_url}")


async def run_async_example() -> None:
    """Fetch multiple users concurrently using the async client."""
    usernames = ["octocat", "torvalds", "gvanrossum", "this-user-does-not-exist-xyz"]

    async with AsyncAPIClient() as client:
        async def fetch_one(username: str):
            try:
                raw = await client.get(f"/users/{username}")
                return username, raw, None
            except APIClientError as e:
                return username, None, e

        results = await asyncio.gather(*(fetch_one(u) for u in usernames))

    print("\n[Async] Concurrent fetch results:")
    for username, raw, error in results:
        if error:
            print(f"  {username}: FAILED — {error}")
        else:
            print(f"  {username}: OK — {raw.get('name') or raw.get('login')}")


def main() -> int:
    # Configure logging ONCE, before anything else runs.
    configure_logging(level="INFO")
    logger.info("Starting API client demo")

    try:
        run_sync_example()
        asyncio.run(run_async_example())
    except Exception:
        # Truly unexpected failure (bug, not a handled API error) — log
        # the full traceback and exit non-zero so CI/shell scripts can
        # detect the failure.
        logger.exception("Unhandled error in main()")
        return 1

    logger.info("Demo completed successfully")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

## Design notes

- **`main.py` is the composition root**: this is the only file that imports and wires together *both* the transport layer (`client.py`/`async_client.py`) and the business logic layer (`service.py`). Every other file in the project could be imported into a completely different application (a FastAPI app, a Celery worker, a test suite) without ever needing `main.py`.
- **Differentiated exception handling at the boundary**: notice `run_sync_example()` distinguishes a 404 (probably a typo'd username — just warn) from a 401/403 (probably a bad token — this is more serious) from other status codes (generic error log). This is the *only* place in the whole codebase that makes UX/behavior decisions based on specific status codes — `service.py` and `client.py` stay generic and reusable.
- **`sys.exit(main())` with an integer return code**: standard Unix convention — 0 means success, non-zero means failure. This matters if this script is ever invoked from a shell script, cron job, or CI pipeline that checks the exit code.
- **Broad `except Exception` only at the very top of `main()`**: this is the single sanctioned "catch everything" in the whole codebase, and it exists purely as a last-resort safety net (log full traceback via `logger.exception`, exit 1) so a truly unexpected bug doesn't crash with a raw unhandled traceback in production — while everywhere else in the codebase we catch specific, expected exception types.
- **Async example demonstrates partial-failure handling**: `fetch_one()` catches errors per-username so one bad username (the intentional 404 in the example) doesn't cancel the other concurrent requests — each result independently reports success or failure.

## Checkpoint

```bash
python main.py
```

Expected output (abbreviated):
```
2024-01-15 10:30:00 | INFO     | __main__ | Starting API client demo

[Sync] octocat (#583231)
  Name: The Octocat
  Public repos: 8
  Profile: https://github.com/octocat

[Async] Concurrent fetch results:
  octocat: OK — The Octocat
  torvalds: OK — Linus Torvalds
  gvanrossum: OK — Guido van Rossum
  this-user-does-not-exist-xyz: FAILED — API returned 404: Not Found

2024-01-15 10:30:01 | INFO     | __main__ | Demo completed successfully
```

Confirm the exit code:
```bash
echo $?
# 0
```

## Troubleshooting

- **`ModuleNotFoundError` on any of the imports** — make sure you're running `python main.py` from the project root with the venv activated, and that every file from Parts 1–10 actually exists with the exact filenames listed.
- **Exit code is 1 unexpectedly** — check the logged traceback from `logger.exception`; most commonly this means `GITHUB_API_TOKEN` isn't set (Part 2's fail-fast `EnvironmentError`) or a typo in an import.
- **Async section runs but sync section didn't print anything** — check the specific-status-code handling in `run_sync_example()`; if you're rate-limited (403) it's swallowed as a logged error rather than a printed result — check the log output above the async section.

---

Next up: **Part 12 — Unit Testing with Mocked HTTP (pytest + respx)**. 
