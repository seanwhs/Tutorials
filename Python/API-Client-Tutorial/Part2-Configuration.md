# Part 2: Configuration & Credentials

## Goal
Load API credentials and settings safely from environment variables, fail loudly if misconfigured, and keep secrets out of source control.

## Why not hardcode the token?

Hardcoding credentials means: (a) they leak the moment you `git push`, (b) you can't run the same code against staging vs prod without editing files, (c) rotating a token requires a code change + redeploy. Environment variables solve all three.

## Step 1 — `.env.example` (safe to commit)

```dotenv
# .env.example — copy to .env and fill in real values. Never commit .env itself.
GITHUB_API_BASE_URL=https://api.github.com
GITHUB_API_TOKEN=ghp_your_personal_access_token_here
GITHUB_API_TIMEOUT_SECONDS=10.0
```

## Step 2 — `.env` (your real values, gitignored)

```dotenv
GITHUB_API_BASE_URL=https://api.github.com
GITHUB_API_TOKEN=ghp_your_real_token_if_you_have_one
GITHUB_API_TIMEOUT_SECONDS=10.0
```

> If you don't have a GitHub token yet: Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. For this tutorial's read-only GET example, no token is strictly required (GitHub allows unauthenticated reads at lower rate limits), but the POST (create issue) example requires one with `repo` scope on a repo you own.

## Step 3 — `config.py`

```python
"""
Centralized configuration loading.

Rationale: Credentials and environment-specific values (base URL, timeouts)
are never hardcoded. Using os.getenv (rather than pydantic-settings) keeps
the dependency list minimal, but the same pattern could be swapped for
`pydantic-settings.BaseSettings` later with zero changes to the rest of
the codebase.
"""
import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()  # loads .env into process env vars (no-op in prod if using real env vars)


@dataclass(frozen=True)
class Settings:
    base_url: str
    api_token: str
    timeout_seconds: float

    @classmethod
    def from_env(cls) -> "Settings":
        token = os.getenv("GITHUB_API_TOKEN")
        if not token:
            # Fail loudly at startup rather than deep inside a request.
            raise EnvironmentError(
                "GITHUB_API_TOKEN is not set. Copy .env.example to .env and fill it in."
            )
        return cls(
            base_url=os.getenv("GITHUB_API_BASE_URL", "https://api.github.com"),
            api_token=token,
            timeout_seconds=float(os.getenv("GITHUB_API_TIMEOUT_SECONDS", "10.0")),
        )


settings = Settings.from_env()
```

## Design notes

- **`frozen=True` dataclass**: settings are immutable once loaded — nothing downstream can accidentally mutate them mid-run.
- **Fail fast**: `Settings.from_env()` raises `EnvironmentError` immediately if `GITHUB_API_TOKEN` is missing, rather than letting a `None` token silently propagate into an `Authorization: Bearer None` header three files later.
- **Single module-level `settings` instance**: imported once (`from config import settings`), acts like a lightweight singleton. Every other module reads from this one object.
- **`load_dotenv()` is a no-op in real deployments**: In production (Docker, Vercel, GitHub Actions, etc.) you set real environment variables and `.env` won't even exist — `load_dotenv()` just silently does nothing if there's no `.env` file found.

## Checkpoint

Test it in a Python shell:

```bash
python -c "from config import settings; print(settings)"
```

Expected (with a real token set):
```
Settings(base_url='https://api.github.com', api_token='ghp_xxx...', timeout_seconds=10.0)
```

Now temporarily rename `.env` to confirm the fail-fast behavior:

```bash
mv .env .env.bak
python -c "from config import settings"
# EnvironmentError: GITHUB_API_TOKEN is not set. Copy .env.example to .env and fill it in.
mv .env.bak .env
```

## Troubleshooting

- **`ModuleNotFoundError: No module named 'dotenv'`** — you installed `python-dotenv` but import it as `dotenv` (this is correct/expected — just make sure the venv is activated).
- **Token loads as empty string, not None** — an empty `GITHUB_API_TOKEN=` line in `.env` sets it to `""`, which is falsy, so the `if not token` check still catches it correctly.
- **Settings not reloading after editing `.env`** — Python caches the `config` module import; restart your script/REPL after changing `.env`.

---

Next up: **Part 3 — Custom Exception Hierarchy**. 
