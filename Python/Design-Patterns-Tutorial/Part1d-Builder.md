# Part 1d — Builder

Separates the **construction** of a complex object from its **representation**, allowing step-by-step assembly.

```python
from dataclasses import dataclass, field

@dataclass
class HttpRequest:
    method: str = "GET"
    url: str = ""
    headers: dict = field(default_factory=dict)
    body: str | None = None

class HttpRequestBuilder:
    """Fluent builder -- each method returns self to allow chaining."""

    def __init__(self):
        self._request = HttpRequest()

    def method(self, method: str) -> "HttpRequestBuilder":
        self._request.method = method
        return self

    def url(self, url: str) -> "HttpRequestBuilder":
        self._request.url = url
        return self

    def header(self, key: str, value: str) -> "HttpRequestBuilder":
        self._request.headers[key] = value
        return self

    def body(self, body: str) -> "HttpRequestBuilder":
        self._request.body = body
        return self

    def build(self) -> HttpRequest:
        return self._request


# Usage -- reads like a sentence, avoids a constructor with 10 positional args
request = (
    HttpRequestBuilder()
    .method("POST")
    .url("https://api.example.com/users")
    .header("Content-Type", "application/json")
    .body('{"name": "Alice"}')
    .build()
)
print(request)
```

**Expected output:**
```
HttpRequest(method='POST', url='https://api.example.com/users', headers={'Content-Type': 'application/json'}, body='{"name": "Alice"}')
```

---

