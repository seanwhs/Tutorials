# Part 0: Series Overview & Prerequisites

## What You're Building

A **production-ready Python API client** for a REST API (we use the public **GitHub REST API** as the running example — free, well-documented, no cost to test against). The architecture is 100% API-agnostic: swap the base URL, Pydantic models, and endpoint paths, and this template works for Stripe, Notion, your internal company API, or anything else.

By the end of this series you will have a fully working package with:

- A reusable `APIClient` class (sync) and `AsyncAPIClient` class (async) — session pooling, shared headers, base URL management
- Pydantic v2 models validating every request and response
- A custom exception hierarchy so callers never touch raw `httpx`/`pydantic` errors
- Retry logic (via `tenacity`) for transient failures
- Structured logging
- A clean **business logic layer** (`service.py`) kept separate from the transport layer (`client.py`)
- Real unit tests that mock the network (no live calls in CI)
- A generalization guide so you can retarget this to *any* API in under an hour
- A production deployment/hardening checklist

## Why This Stack (2026 Standard)

| Tool | Purpose | Why |
|---|---|---|
| `httpx` | HTTP client | Sync **and** async in one library, HTTP/2, `requests`-compatible API |
| `Pydantic v2` | Data validation | Rust core (fast), fails loudly on schema drift instead of passing corrupt data downstream |
| `tenacity` | Retries | Declarative retry/backoff for transient network failures — no hand-rolled retry loops |
| `python-dotenv` | Env loading | Local `.env` file support without leaking secrets into source control |
| standard `logging` | Observability | No extra dependency; swappable for `loguru` later if you want prettier output |

**Design principle carried through the whole series:** the **transport layer** (how to talk HTTP, auth headers, retries, error translation) is completely separate from the **business logic layer** (what the API *means* — "get a user", "create an issue"). This is what makes the client testable and reusable.

## Prerequisites

- Python 3.11+ (3.12 recommended) — `python3 --version`
- Basic familiarity with `pip`/virtual environments
- A GitHub account + a **Personal Access Token** (classic or fine-grained) with minimal scopes — only needed from Part 2 onward, and only if you want to make *real* calls. Every part still works read-only against public endpoints with no token for the GET example.
- Comfortable reading type hints (`Optional[str]`, `list[str]`, etc.)

## Final Project Structure (what we build toward)

```
project/
├── .env
├── .env.example
├── config.py            # env/credential loading (Part 2)
├── exceptions.py         # custom exception hierarchy (Part 3)
├── models.py              # Pydantic v2 schemas (Part 4)
├── client.py               # sync APIClient (Part 5-6)
├── async_client.py          # async AsyncAPIClient (Part 7)
├── service.py                 # business logic layer (Parts 8-9)
├── logging_config.py           # logging setup (Part 10)
├── main.py                      # example usage / CLI (Part 13)
├── tests/
│   └── test_service.py            # mocked unit tests (Part 12)
├── requirements.txt
└── pyproject.toml (optional)
```

## Series Index

See note: **"API Client Tutorial - INDEX (Start Here)"** for the full part list and reading order.

## How to Use This Series

Each part is self-contained with copy-pasteable code, a **Checkpoint** (how to verify it works), and a **Troubleshooting** section for common errors. Work through them in order — later parts assume earlier files already exist.

---

Next up: **Part 1 — Environment Setup & Dependencies**.
