# API Client Tutorial Series

A production-ready Python REST API client, built incrementally, using `httpx` + `Pydantic v2` + `tenacity`. Reference implementation targets the public **GitHub REST API**, but every part calls out how to retarget it to any API (Stripe, Notion, an internal service, etc.).

## Parts

| # | Title | Covers |
|---|---|---|
| 0 | Series Overview & Prerequisites | What you're building, final project structure |
| 1 | Environment Setup & Dependencies | venv, `requirements.txt`, project scaffolding |
| 2 | Configuration & Credentials | `config.py`, `.env` handling, fail-fast loading |
| 3 | Custom Exception Hierarchy | `exceptions.py` |
| 4 | Pydantic v2 Request/Response Models | `models.py` |
| 5 | Building the Sync `APIClient` Core | session pooling, headers, lifecycle |
| 6 | Sync `APIClient` Request Methods, Error Handling & Retries | `get()`/`post()`, error translation, `tenacity` |
| 7 | Async `AsyncAPIClient` | concurrency with `asyncio` |
| 8 | Business Logic Layer — reads | `service.py` read operations |
| 9 | Business Logic Layer — writes | `service.py` write ops + validation, idempotency |
| 10 | Logging Configuration & Observability | `logging_config.py` |
| 11 | Putting It All Together | `main.py` end-to-end example |
| 12 | Unit Testing with Mocked HTTP | `pytest` + `respx` |
| 13 | Generalizing This Template to Any API | retargeting checklist |
| 14 | Production Hardening & Deployment Checklist | secrets, rate limits, monitoring |
| — | Conclusion | recap + next steps (pagination, caching, GraphQL, webhooks) |
