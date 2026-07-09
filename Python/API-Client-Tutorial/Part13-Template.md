# Part 13: Generalizing This Template to Any API

## Goal
A step-by-step checklist for retargeting everything built in Parts 1–12 at a *different* REST API — Stripe, Notion, Shopify, or your own company's internal API — in under an hour.

## The 7-step retargeting checklist

### 1. Update `.env` / `.env.example` and `config.py`
Change `GITHUB_API_BASE_URL` → `<YOUR_API>_BASE_URL`, `GITHUB_API_TOKEN` → whatever the provider calls it. Some APIs need more than one credential (e.g. an API key **and** a webhook secret, or an OAuth client ID/secret pair) — just add more fields to the `Settings` dataclass and more `os.getenv` calls in `from_env()`. Nothing else in the codebase needs to change.

### 2. Update authentication in `_default_headers()`
This is the part that varies most between APIs:

| Auth style | Header shape |
|---|---|
| Bearer token (GitHub, most modern APIs) | `Authorization: Bearer <token>` |
| Raw API key header (many SaaS APIs) | `X-API-Key: <key>` |
| Basic auth (some legacy/enterprise APIs) | `Authorization: Basic <base64(user:pass)>` — `httpx.Client(auth=(user, pass))` handles this automatically instead of a manual header |
| OAuth2 client credentials | Requires a token-fetch step first (see "OAuth2" note below) |

For Basic auth, you don't even need a custom header — pass `auth=(username, password)` directly to `httpx.Client(...)`/`AsyncClient(...)` in the constructor, and `httpx` handles the encoding.

**OAuth2 client-credentials flow**: add a method that fetches/caches an access token (with expiry tracking) before the first request, and refreshes it when expired. This is the one auth style that needs genuinely new code beyond a header — worth a dedicated `TokenManager` class if you go this route, keeping token refresh logic separate from the request logic in `_request()`.

### 3. Replace `models.py` with the new API's schemas
This is almost always the biggest time investment. Two approaches:

- **Manual** (what we did in Part 4): read the API's docs, write Pydantic models by hand for each response/request shape you actually use. Best for APIs you'll interact with in a handful of ways.
- **Auto-generated from an OpenAPI/Swagger spec**: if the provider publishes an OpenAPI spec (Stripe, many modern APIs do), use `datamodel-code-generator` to generate Pydantic models automatically:
  ```bash
  pip install datamodel-code-generator
  datamodel-codegen --input openapi.json --input-file-type openapi --output models_generated.py
  ```
  This can save enormous time for APIs with dozens/hundreds of endpoints, at the cost of less control over model naming/structure. A common pattern: use generated models as a starting point, then hand-write a thinner set of "the fields I actually use" models on top for the ones your service layer exposes.

### 4. Update endpoint paths in `service.py`
Replace `f"/users/{username}"` and `f"/repos/{owner}/{repo}/issues"` with the new API's actual paths. Keep the same shape: one small public method per domain operation, private `_validate_*` helpers for response parsing.

### 5. Adjust error-code handling in `main.py` (or wherever you handle exceptions at the application boundary)
Every API has its own status code conventions. Common variations to check the target API's docs for:
- Does it use `429` for rate limiting, or a custom code?
- Does it return a `Retry-After` header you should respect (read `response.headers.get("Retry-After")` and use it to inform backoff instead of blind exponential backoff)?
- Does it use `422` for validation errors (like GitHub) or `400`? Adjust any status-code-specific branches accordingly.

### 6. Update `_raise_for_status()` if the API wraps errors in a nonstandard body shape
Some APIs return error details in a specific JSON shape (e.g. `{"error": {"code": "...", "message": "..."}}`). You can enrich `APIStatusError` to parse this out for a more informative message:
```python
def _raise_for_status(self, response: httpx.Response) -> None:
    if response.is_success:
        return
    try:
        error_body = response.json()
        message = error_body.get("error", {}).get("message", response.reason_phrase)
    except json.JSONDecodeError:
        message = response.reason_phrase
    raise APIStatusError(status_code=response.status_code, message=message, body=response.text[:500])
```

### 7. Update tests
Swap the `respx.mock` URLs/response bodies in `test_client.py` to match the new API's endpoints and realistic sample responses (most API docs include example JSON responses you can copy directly into test fixtures).

## What you should NOT need to change

If the layering from Parts 5–9 was followed correctly, these stay **completely untouched**:
- `exceptions.py` — the exception hierarchy is API-agnostic by design
- `client.py`/`async_client.py`'s retry logic, context manager lifecycle, and `_request`/`_parse_json` structure
- `logging_config.py`
- The overall test *structure* (only the mocked data/URLs change)

If you find yourself needing to change these files for a new API, it's a signal the original abstraction leaked some GitHub-specific assumption — worth revisiting.

## Worked mini-example: retargeting to a hypothetical "Acme API" using an API key header

```python
# config.py changes
@dataclass(frozen=True)
class Settings:
    base_url: str
    api_key: str          # renamed from api_token
    timeout_seconds: float

    @classmethod
    def from_env(cls) -> "Settings":
        key = os.getenv("ACME_API_KEY")
        if not key:
            raise EnvironmentError("ACME_API_KEY is not set.")
        return cls(
            base_url=os.getenv("ACME_API_BASE_URL", "https://api.acme.com/v1"),
            api_key=key,
            timeout_seconds=float(os.getenv("ACME_API_TIMEOUT_SECONDS", "10.0")),
        )

# client.py changes
def _default_headers(self) -> dict[str, str]:
    return {
        "X-API-Key": self._api_key,       # different header name/style
        "Accept": "application/json",
        "User-Agent": "api-client-tutorial/1.0",
    }

# models.py — new schemas
class AcmeWidget(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    name: str
    price_cents: int

# service.py — new domain method
def get_widget(self, widget_id: str) -> AcmeWidget:
    raw = self._client.get(f"/widgets/{widget_id}")
    return AcmeWidget.model_validate(raw)
```

That's the entire diff needed to retarget the whole architecture at a new API — everything else (retries, logging, exception translation, test structure) is reused as-is.

## Troubleshooting

- **Auto-generated models from `datamodel-code-generator` are messy/deeply nested** — this is common with large OpenAPI specs; consider generating once, then manually curating down to a smaller `models.py` with just the fields your service layer actually needs, rather than importing hundreds of generated classes wholesale.
- **New API uses GraphQL, not REST** — this template's `_request()` method still works (GraphQL is just a POST with a `{"query": "...", "variables": {...}}` body to a single `/graphql` endpoint) but you'll typically drop the `get()`/multiple-endpoint-paths pattern in favor of one `query()`/`mutate()` method — see the Conclusion note for further reading pointers.
- **New API has strict rate limits with documented reset windows** — worth adding a small rate-limiter (e.g. `asyncio-throttle` or a simple token-bucket) in front of `_request()` rather than relying purely on reactive retry-after-429 handling.

---

Next up: **Part 14 — Production Hardening & Deployment Checklist**. 
